# frozen_string_literal: true

require 'json'
require 'open3'
require 'tmpdir'
require 'fileutils'
require 'rbconfig'

describe 'openproject::backup' do
  let(:task_dir) { File.expand_path('../../tasks', __dir__) }
  let(:task_script) { File.join(task_dir, 'backup.rb') }
  let(:task_metadata) { File.join(task_dir, 'backup.json') }

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

  # ---------------------------------------------------------------------------
  # Task metadata (backup.json)
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

    it 'defines backup_dir parameter with correct type and default' do
      param = metadata.dig('parameters', 'backup_dir')
      expect(param).not_to be_nil
      expect(param['type']).to eq('Optional[String[1]]')
      expect(param['default']).to eq('/var/db/openproject/backup')
    end

    it 'requires puppet-agent' do
      reqs = metadata.dig('implementations', 0, 'requirements')
      expect(reqs).to include('puppet-agent')
    end
  end

  # ---------------------------------------------------------------------------
  # Task script (backup.rb)
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
        stdout, _stderr, status = run_task
        expect(status.exitstatus).to eq(1)

        result = JSON.parse(stdout)
        expect(result['_error']['kind']).to eq('openproject/not-root')
        expect(result['_error']['msg']).to match(%r{root})
      end
    end

    context 'when running as root' do
      context 'when openproject command is not installed' do
        let(:empty_bin) { Dir.mktmpdir('op-task-test-') }

        after { FileUtils.rm_rf(empty_bin) }

        it 'returns a command-not-found error' do
          # PATH contains only an empty dir plus system dirs - no openproject
          stdout, _stderr, status = run_task(
            as_root: true,
            env: { 'PATH' => "#{empty_bin}:/usr/bin:/bin" }
          )

          expect(status.exitstatus).to eq(1)

          result = JSON.parse(stdout)
          expect(result['_error']['kind']).to eq('openproject/command-not-found')
          expect(result['_error']['msg']).to match(%r{openproject})
        end
      end

      context 'when openproject backup succeeds' do
        let(:tmpdir) { Dir.mktmpdir('op-task-test-') }

        before do
          bin_dir    = File.join(tmpdir, 'bin')
          backup_dir = File.join(tmpdir, 'backup')
          FileUtils.mkdir_p(bin_dir)
          FileUtils.mkdir_p(backup_dir)

          # Mock openproject script that creates timestamped backup files
          mock_script = File.join(bin_dir, 'openproject')
          File.write(mock_script, <<~SH)
            #!/bin/sh
            if [ "$1" = "run" ] && [ "$2" = "backup" ]; then
              TIMESTAMP=$(date +%Y%m%d%H%M%S)
              printf 'x%.0s' $(seq 1 1024) > "#{backup_dir}/postgresql-dump-${TIMESTAMP}.pgdump"
              printf 'y%.0s' $(seq 1 2048) > "#{backup_dir}/attachments-${TIMESTAMP}.tar.gz"
              printf 'z%.0s' $(seq 1 512)  > "#{backup_dir}/conf-${TIMESTAMP}.tar.gz"
              echo "backup completed"
              exit 0
            fi
            exit 1
          SH
          File.chmod(0o755, mock_script)
        end

        after { FileUtils.rm_rf(tmpdir) }

        it 'returns success with backup file details' do
          backup_dir = File.join(tmpdir, 'backup')
          stdout, _stderr, status = run_task(
            params: { 'backup_dir' => backup_dir },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )

          expect(status.exitstatus).to eq(0)

          result = JSON.parse(stdout)
          expect(result['backup_dir']).to eq(backup_dir)
          expect(result['file_count']).to eq(3)
          expect(result['files']).to be_an(Array)
          expect(result['files'].length).to eq(3)
        end

        it 'reports correct file names matching the backup pattern' do
          stdout, _stderr, _status = run_task(
            params: { 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )
          result = JSON.parse(stdout)
          names = result['files'].map { |f| f['name'] }

          expect(names).to include(a_string_matching(%r{^postgresql-dump-.*\.pgdump$}))
          expect(names).to include(a_string_matching(%r{^attachments-.*\.tar\.gz$}))
          expect(names).to include(a_string_matching(%r{^conf-.*\.tar\.gz$}))
        end

        it 'includes size information for each file' do
          stdout, _stderr, _status = run_task(
            params: { 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )
          result = JSON.parse(stdout)

          result['files'].each do |file|
            expect(file).to include('path', 'name', 'size_bytes', 'size_human')
            expect(file['size_bytes']).to be_a(Integer)
            expect(file['size_bytes']).to be > 0
            expect(file['size_human']).to match(%r{\d+\.\d+ \w+})
          end
        end

        it 'reports total backup size' do
          stdout, _stderr, _status = run_task(
            params: { 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )
          result = JSON.parse(stdout)

          expect(result['total_bytes']).to be_a(Integer)
          expect(result['total_bytes']).to eq(result['files'].sum { |f| f['size_bytes'] })
          expect(result['total_human']).to be_a(String)
        end

        it 'captures stdout from the backup command' do
          stdout, _stderr, _status = run_task(
            params: { 'backup_dir' => File.join(tmpdir, 'backup') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )
          result = JSON.parse(stdout)

          expect(result['stdout']).to match(%r{backup completed})
        end

        it 'uses the default backup_dir when not specified' do
          # Passes no backup_dir param - the script defaults to
          # /var/db/openproject/backup. Since that directory likely does not
          # exist on the test host, the result will have 0 new files but the
          # task still succeeds (backup command itself succeeds via mock).
          stdout, _stderr, status = run_task(
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )

          expect(status.exitstatus).to eq(0)

          result = JSON.parse(stdout)
          expect(result['backup_dir']).to eq('/var/db/openproject/backup')
        end
      end

      context 'when openproject backup fails' do
        let(:tmpdir) { Dir.mktmpdir('op-task-test-') }
        let(:bin_dir) { File.join(tmpdir, 'bin') }

        before do
          FileUtils.mkdir_p(bin_dir)

          mock_script = File.join(bin_dir, 'openproject')
          File.write(mock_script, <<~SH)
            #!/bin/sh
            echo "Backup failed: database connection refused" >&2
            exit 1
          SH
          File.chmod(0o755, mock_script)
        end

        after { FileUtils.rm_rf(tmpdir) }

        it 'returns a backup-failed error' do
          stdout, _stderr, status = run_task(
            as_root: true,
            env: { 'PATH' => "#{bin_dir}:/usr/bin:/bin" }
          )

          expect(status.exitstatus).to eq(1)

          result = JSON.parse(stdout)
          expect(result['_error']['kind']).to eq('openproject/backup-failed')
        end

        it 'includes the exit code in error details' do
          stdout, _stderr, _status = run_task(
            as_root: true,
            env: { 'PATH' => "#{bin_dir}:/usr/bin:/bin" }
          )
          result = JSON.parse(stdout)

          expect(result['_error']['details']['exitcode']).to eq(1)
        end

        it 'includes stderr output in error details' do
          stdout, _stderr, _status = run_task(
            as_root: true,
            env: { 'PATH' => "#{bin_dir}:/usr/bin:/bin" }
          )
          result = JSON.parse(stdout)

          expect(result['_error']['details']['stderr']).to match(%r{database connection refused})
        end
      end

      context 'when backup_dir does not exist initially' do
        let(:tmpdir) { Dir.mktmpdir('op-task-test-') }

        before do
          bin_dir    = File.join(tmpdir, 'bin')
          backup_dir = File.join(tmpdir, 'nonexistent')
          FileUtils.mkdir_p(bin_dir)

          # Mock openproject that creates the backup_dir and files
          mock_script = File.join(bin_dir, 'openproject')
          File.write(mock_script, <<~SH)
            #!/bin/sh
            if [ "$1" = "run" ] && [ "$2" = "backup" ]; then
              mkdir -p "#{backup_dir}"
              echo "data" > "#{backup_dir}/postgresql-dump-test.pgdump"
              exit 0
            fi
            exit 1
          SH
          File.chmod(0o755, mock_script)
        end

        after { FileUtils.rm_rf(tmpdir) }

        it 'handles a non-existent backup_dir gracefully' do
          stdout, _stderr, status = run_task(
            params: { 'backup_dir' => File.join(tmpdir, 'nonexistent') },
            env: { 'PATH' => "#{File.join(tmpdir, 'bin')}:/usr/bin:/bin" },
            as_root: true
          )

          expect(status.exitstatus).to eq(0)

          result = JSON.parse(stdout)
          expect(result['file_count']).to eq(1)
          expect(result['files'].first['name']).to eq('postgresql-dump-test.pgdump')
        end
      end
    end
  end
end
