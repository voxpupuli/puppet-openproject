# frozen_string_literal: true

require 'json'
require 'open3'
require 'tmpdir'
require 'fileutils'
require 'rbconfig'

describe 'openproject::restore' do
  let(:task_dir) { File.expand_path('../../tasks', __dir__) }
  let(:task_script) { File.join(task_dir, 'restore.rb') }
  let(:task_metadata) { File.join(task_dir, 'restore.json') }

  # Run the task script as a subprocess.
  #
  # Always stubs +Process.uid+ so the test is deterministic regardless of
  # the actual user running the suite (voxbox containers run as root).
  # When +as_root+ is true the stub returns 0; otherwise it returns 1000.
  def run_task(params: {}, env: {}, as_root: false)
    uid = as_root ? 0 : 1000
    wrapper = <<~RUBY
      module Process
        def self.uid; #{uid}; end
      end
      load #{task_script.inspect}
    RUBY

    Open3.capture3(env, RbConfig.ruby, '-e', wrapper, stdin_data: params.to_json)
  end

  # Create the three required backup files in the given directory.
  def create_backup_files(dir, timestamp)
    File.write(File.join(dir, "postgresql-dump-#{timestamp}.pgdump"), 'PGDUMP')
    File.write(File.join(dir, "attachments-#{timestamp}.tar.gz"), 'ATTACH')
    File.write(File.join(dir, "conf-#{timestamp}.tar.gz"), 'CONF')
  end

  # ---------------------------------------------------------------------------
  # Task metadata (restore.json)
  # ---------------------------------------------------------------------------
  describe 'task metadata' do
    subject(:metadata) { JSON.parse(File.read(task_metadata)) }

    it 'is valid JSON with a description' do
      expect(metadata['description']).to be_a(String)
      expect(metadata['description']).not_to be_empty
    end

    it 'uses stdin input method' do
      expect(metadata['input_method']).to eq('stdin')
    end

    it 'defines timestamp as a required String parameter' do
      param = metadata.dig('parameters', 'timestamp')
      expect(param).not_to be_nil
      expect(param['type']).to eq('String[1]')
      expect(param).not_to have_key('default')
    end

    it 'defines backup_dir parameter with correct type and default' do
      param = metadata.dig('parameters', 'backup_dir')
      expect(param).not_to be_nil
      expect(param['type']).to eq('Optional[String[1]]')
      expect(param['default']).to eq('/var/db/openproject/backup')
    end

    it 'defines pg_no_owner parameter as optional boolean' do
      param = metadata.dig('parameters', 'pg_no_owner')
      expect(param).not_to be_nil
      expect(param['type']).to eq('Optional[Boolean]')
      expect(param['default']).to be false
    end

    it 'requires puppet-agent' do
      reqs = metadata.dig('implementations', 0, 'requirements')
      expect(reqs).to include('puppet-agent')
    end
  end

  # ---------------------------------------------------------------------------
  # Task script (restore.rb)
  # ---------------------------------------------------------------------------
  describe 'task script' do
    it 'has valid Ruby syntax' do
      stdout, _stderr, status = Open3.capture3(RbConfig.ruby, '-c', task_script)
      expect(status).to be_success, stdout
    end

    it 'is executable' do
      expect(File).to be_executable(task_script)
    end
  end

  # ---------------------------------------------------------------------------
  # Execution
  # ---------------------------------------------------------------------------
  describe 'execution' do
    context 'when not running as root' do
      it 'returns a not-root error' do
        stdout, _stderr, status = run_task(params: { 'timestamp' => '20240101120000' })
        expect(status.exitstatus).to eq(1)

        result = JSON.parse(stdout)
        expect(result['_error']['kind']).to eq('openproject/not-root')
        expect(result['_error']['msg']).to match(%r{root})
      end
    end

    context 'when running as root' do
      context 'when openproject command is not installed' do
        let(:empty_bin) { Dir.mktmpdir('op-restore-test-') }

        after { FileUtils.rm_rf(empty_bin) }

        it 'returns a command-not-found error' do
          stdout, _stderr, status = run_task(
            params: { 'timestamp' => '20240101120000' },
            as_root: true,
            env: { 'PATH' => "#{empty_bin}:/usr/bin:/bin" }
          )

          expect(status.exitstatus).to eq(1)

          result = JSON.parse(stdout)
          expect(result['_error']['kind']).to eq('openproject/command-not-found')
        end
      end

      context 'when pg_restore is not installed' do
        let(:tmpdir) { Dir.mktmpdir('op-restore-test-') }

        before do
          bin_dir = File.join(tmpdir, 'bin')
          FileUtils.mkdir_p(bin_dir)

          # Provide openproject but not pg_restore
          mock = File.join(bin_dir, 'openproject')
          File.write(mock, "#!/bin/sh\nexit 0\n")
          File.chmod(0o755, mock)

          # Provide a which that only finds openproject
          mock_which = File.join(bin_dir, 'which')
          File.write(mock_which, <<~SH)
            #!/bin/sh
            for cmd in "$@"; do
              found=$(command -v "$cmd" 2>/dev/null)
              if [ -n "$found" ]; then echo "$found"; exit 0; fi
            done
            exit 1
          SH
          File.chmod(0o755, mock_which)
        end

        after { FileUtils.rm_rf(tmpdir) }

        it 'returns a pg-restore-not-found error' do
          stdout, _stderr, status = run_task(
            params: { 'timestamp' => '20240101120000' },
            as_root: true,
            env: { 'PATH' => File.join(tmpdir, 'bin') }
          )

          expect(status.exitstatus).to eq(1)

          result = JSON.parse(stdout)
          expect(result['_error']['kind']).to eq('openproject/pg-restore-not-found')
        end
      end

      context 'when required backup files are missing' do
        let(:tmpdir) { Dir.mktmpdir('op-restore-test-') }

        before do
          bin_dir = File.join(tmpdir, 'bin')
          FileUtils.mkdir_p(bin_dir)
          FileUtils.mkdir_p(File.join(tmpdir, 'backup'))

          # Provide openproject and pg_restore
          %w[openproject pg_restore].each do |cmd|
            mock = File.join(bin_dir, cmd)
            File.write(mock, "#!/bin/sh\nexit 0\n")
            File.chmod(0o755, mock)
          end
        end

        after { FileUtils.rm_rf(tmpdir) }

        it 'returns a missing-backup-files error' do
          stdout, _stderr, status = run_task(
            params: { 'timestamp' => '99999999999999', 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )

          expect(status.exitstatus).to eq(1)

          result = JSON.parse(stdout)
          expect(result['_error']['kind']).to eq('openproject/missing-backup-files')
          expect(result['_error']['details']['missing']).to be_an(Array)
          expect(result['_error']['details']['missing'].length).to eq(3)
        end

        it 'lists all missing required components' do
          stdout, _stderr, _status = run_task(
            params: { 'timestamp' => '99999999999999', 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )
          result = JSON.parse(stdout)
          components = result['_error']['details']['missing'].map { |m| m['component'] }

          expect(components).to include('database', 'attachments', 'configuration')
        end
      end

      context 'when restore succeeds' do
        let(:tmpdir) { Dir.mktmpdir('op-restore-test-') }
        let(:timestamp) { '20240101120000' }

        before do
          bin_dir    = File.join(tmpdir, 'bin')
          backup_dir = File.join(tmpdir, 'backup')
          FileUtils.mkdir_p(bin_dir)
          FileUtils.mkdir_p(backup_dir)

          create_backup_files(backup_dir, timestamp)

          # Mock service command
          mock_service = File.join(bin_dir, 'service')
          File.write(mock_service, <<~SH)
            #!/bin/sh
            echo "service $2 $1"
            exit 0
          SH
          File.chmod(0o755, mock_service)

          # Mock tar command (just succeeds)
          mock_tar = File.join(bin_dir, 'tar')
          File.write(mock_tar, "#!/bin/sh\nexit 0\n")
          File.chmod(0o755, mock_tar)

          # Mock openproject that returns a DATABASE_URL
          mock_op = File.join(bin_dir, 'openproject')
          File.write(mock_op, <<~SH)
            #!/bin/sh
            if [ "$1" = "config:get" ] && [ "$2" = "DATABASE_URL" ]; then
              echo "postgres://openproject:secret@localhost/openproject"
              exit 0
            fi
            exit 0
          SH
          File.chmod(0o755, mock_op)

          # Mock pg_restore
          mock_pg = File.join(bin_dir, 'pg_restore')
          File.write(mock_pg, "#!/bin/sh\nexit 0\n")
          File.chmod(0o755, mock_pg)
        end

        after { FileUtils.rm_rf(tmpdir) }

        it 'returns success with restored components' do
          stdout, _stderr, status = run_task(
            params: { 'timestamp' => timestamp, 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )

          expect(status.exitstatus).to eq(0)

          result = JSON.parse(stdout)
          expect(result['timestamp']).to eq(timestamp)
          expect(result['restored']).to include('database', 'attachments', 'configuration')
        end

        it 'reports optional repos as skipped when absent' do
          stdout, _stderr, _status = run_task(
            params: { 'timestamp' => timestamp, 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )
          result = JSON.parse(stdout)

          expect(result['skipped']).to include('git_repositories', 'svn_repositories')
        end

        it 'records all execution steps' do
          stdout, _stderr, _status = run_task(
            params: { 'timestamp' => timestamp, 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )
          result = JSON.parse(stdout)
          step_names = result['steps'].map { |s| s['step'] }

          expect(step_names).to include('stop_service', 'restore_attachments',
                                        'restore_configuration', 'restore_database',
                                        'restart_service')
        end

        it 'includes git and svn repos when backup files are present' do
          backup_dir = File.join(tmpdir, 'backup')
          File.write(File.join(backup_dir, "git-repositories-#{timestamp}.tar.gz"), 'GIT')
          File.write(File.join(backup_dir, "svn-repositories-#{timestamp}.tar.gz"), 'SVN')

          stdout, _stderr, _status = run_task(
            params: { 'timestamp' => timestamp, 'backup_dir' => backup_dir },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )
          result = JSON.parse(stdout)

          expect(result['restored']).to include('git_repositories', 'svn_repositories')
          expect(result['skipped']).to be_empty
        end
      end

      context 'when service stop fails' do
        let(:tmpdir) { Dir.mktmpdir('op-restore-test-') }
        let(:timestamp) { '20240101120000' }

        before do
          bin_dir    = File.join(tmpdir, 'bin')
          backup_dir = File.join(tmpdir, 'backup')
          FileUtils.mkdir_p(bin_dir)
          FileUtils.mkdir_p(backup_dir)

          create_backup_files(backup_dir, timestamp)

          # Provide openproject and pg_restore
          %w[openproject pg_restore].each do |cmd|
            mock = File.join(bin_dir, cmd)
            File.write(mock, "#!/bin/sh\nexit 0\n")
            File.chmod(0o755, mock)
          end

          # Service stop fails
          mock_service = File.join(bin_dir, 'service')
          File.write(mock_service, <<~SH)
            #!/bin/sh
            echo "Failed to stop service" >&2
            exit 1
          SH
          File.chmod(0o755, mock_service)
        end

        after { FileUtils.rm_rf(tmpdir) }

        it 'returns a service-stop-failed error' do
          stdout, _stderr, status = run_task(
            params: { 'timestamp' => timestamp, 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )

          expect(status.exitstatus).to eq(1)

          result = JSON.parse(stdout)
          expect(result['_error']['kind']).to eq('openproject/service-stop-failed')
        end
      end

      context 'when pg_restore fails' do
        let(:tmpdir) { Dir.mktmpdir('op-restore-test-') }
        let(:timestamp) { '20240101120000' }

        before do
          bin_dir    = File.join(tmpdir, 'bin')
          backup_dir = File.join(tmpdir, 'backup')
          FileUtils.mkdir_p(bin_dir)
          FileUtils.mkdir_p(backup_dir)

          create_backup_files(backup_dir, timestamp)

          mock_service = File.join(bin_dir, 'service')
          File.write(mock_service, "#!/bin/sh\nexit 0\n")
          File.chmod(0o755, mock_service)

          mock_tar = File.join(bin_dir, 'tar')
          File.write(mock_tar, "#!/bin/sh\nexit 0\n")
          File.chmod(0o755, mock_tar)

          mock_op = File.join(bin_dir, 'openproject')
          File.write(mock_op, <<~SH)
            #!/bin/sh
            if [ "$1" = "config:get" ]; then
              echo "postgres://localhost/openproject"
              exit 0
            fi
            exit 0
          SH
          File.chmod(0o755, mock_op)

          mock_pg = File.join(bin_dir, 'pg_restore')
          File.write(mock_pg, "#!/bin/sh\nexit 1\n")
          File.chmod(0o755, mock_pg)
        end

        after { FileUtils.rm_rf(tmpdir) }

        it 'returns a pg-restore-failed error' do
          stdout, _stderr, status = run_task(
            params: { 'timestamp' => timestamp, 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )

          expect(status.exitstatus).to eq(1)

          result = JSON.parse(stdout)
          expect(result['_error']['kind']).to eq('openproject/pg-restore-failed')
        end

        it 'attempts to restart the service after failure' do
          stdout, _stderr, _status = run_task(
            params: { 'timestamp' => timestamp, 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )
          result = JSON.parse(stdout)
          step_names = result['_error']['details']['steps'].map { |s| s['step'] }

          expect(step_names).to include('restart_service_after_failure')
        end
      end

      context 'with pg_no_owner enabled' do
        let(:tmpdir) { Dir.mktmpdir('op-restore-test-') }
        let(:timestamp) { '20240101120000' }

        before do
          bin_dir    = File.join(tmpdir, 'bin')
          backup_dir = File.join(tmpdir, 'backup')
          FileUtils.mkdir_p(bin_dir)
          FileUtils.mkdir_p(backup_dir)

          create_backup_files(backup_dir, timestamp)

          mock_service = File.join(bin_dir, 'service')
          File.write(mock_service, "#!/bin/sh\nexit 0\n")
          File.chmod(0o755, mock_service)

          mock_tar = File.join(bin_dir, 'tar')
          File.write(mock_tar, "#!/bin/sh\nexit 0\n")
          File.chmod(0o755, mock_tar)

          mock_op = File.join(bin_dir, 'openproject')
          File.write(mock_op, <<~SH)
            #!/bin/sh
            if [ "$1" = "config:get" ]; then
              echo "postgres://localhost/openproject"
              exit 0
            fi
            exit 0
          SH
          File.chmod(0o755, mock_op)

          # pg_restore logs its arguments so we can verify --no-owner
          mock_pg = File.join(bin_dir, 'pg_restore')
          File.write(mock_pg, <<~SH)
            #!/bin/sh
            echo "pg_restore $*"
            exit 0
          SH
          File.chmod(0o755, mock_pg)
        end

        after { FileUtils.rm_rf(tmpdir) }

        it 'passes --no-owner to pg_restore' do
          stdout, _stderr, status = run_task(
            params: { 'timestamp' => timestamp, 'backup_dir' => File.join(tmpdir, 'backup'), 'pg_no_owner' => true },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )

          expect(status.exitstatus).to eq(0)

          result = JSON.parse(stdout)
          db_step = result['steps'].find { |s| s['step'] == 'restore_database' }
          expect(db_step['command']).to include('--no-owner')
        end
      end
    end
  end
end
