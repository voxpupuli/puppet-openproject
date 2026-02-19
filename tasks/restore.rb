#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

#
# openproject::restore - Bolt task
#
# Restores an OpenProject package-based installation from a timestamped
# backup set. The restore order follows the official procedure:
#
#   1. Stop the openproject service
#   2. Restore attachments  -> /var/db/openproject/files
#   3. Restore configuration -> /etc/openproject
#   4. Restore git repos    -> /var/db/openproject/git    (if present)
#   5. Restore svn repos    -> /var/db/openproject/svn    (if present)
#   6. Restore PostgreSQL database via pg_restore
#   7. Restart the openproject service
#
# Reference: https://www.openproject.org/docs/installation-and-operations/
#            operation/restoring/#package-based-installation-debrpm
#

require 'json'
require 'open3'

# --- helpers ----------------------------------------------------------------

def error(msg, kind, details = {})
  result = {
    '_error' => {
      'msg'     => msg,
      'kind'    => kind,
      'details' => details,
    },
  }
  $stdout.puts(result.to_json)
  exit 1
end

def run_cmd(*cmd)
  stdout, stderr, status = Open3.capture3(*cmd)
  { 'stdout' => stdout, 'stderr' => stderr, 'exitcode' => status.exitstatus, 'success' => status.success? }
end

# --- main -------------------------------------------------------------------

params      = JSON.parse($stdin.read)
timestamp   = params.fetch('timestamp')
backup_dir  = params.fetch('backup_dir', '/var/db/openproject/backup')
pg_no_owner = params.fetch('pg_no_owner', false)

# Must run as root.
unless Process.uid.zero?
  error(
    'This task must run as root (restore requires root privileges).',
    'openproject/not-root'
  )
end

# Verify the openproject CLI is available.
openproject_bin, = Open3.capture2('which', 'openproject')
openproject_bin.strip!
if openproject_bin.empty?
  error(
    'The openproject command was not found in PATH. Is OpenProject installed?',
    'openproject/command-not-found'
  )
end

# Verify pg_restore is available.
pg_restore_bin, = Open3.capture2('which', 'pg_restore')
pg_restore_bin.strip!
if pg_restore_bin.empty?
  error(
    'pg_restore was not found in PATH. Is PostgreSQL client installed?',
    'openproject/pg-restore-not-found'
  )
end

# Build file map: component -> { path, target_dir, required }
files = {
  'database'         => { 'path' => File.join(backup_dir, "postgresql-dump-#{timestamp}.pgdump"),
                          'required' => true },
  'attachments'      => { 'path' => File.join(backup_dir, "attachments-#{timestamp}.tar.gz"),
                          'target' => '/var/db/openproject/files',
                          'required' => true },
  'configuration'    => { 'path' => File.join(backup_dir, "conf-#{timestamp}.tar.gz"),
                          'target' => '/etc/openproject',
                          'required' => true },
  'git_repositories' => { 'path' => File.join(backup_dir, "git-repositories-#{timestamp}.tar.gz"),
                          'target' => '/var/db/openproject/git',
                          'required' => false },
  'svn_repositories' => { 'path' => File.join(backup_dir, "svn-repositories-#{timestamp}.tar.gz"),
                          'target' => '/var/db/openproject/svn',
                          'required' => false },
}

# Check that all required files exist.
missing = files.select { |_, v| v['required'] && !File.exist?(v['path']) }
unless missing.empty?
  error(
    "Required backup files not found for timestamp #{timestamp}: #{missing.keys.join(', ')}.",
    'openproject/missing-backup-files',
    { 'missing' => missing.map { |k, v| { 'component' => k, 'path' => v['path'] } } }
  )
end

steps = []

# 1. Stop the service.
result = run_cmd('service', 'openproject', 'stop')
steps << { 'step' => 'stop_service', 'command' => 'service openproject stop' }.merge(result)
unless result['success']
  error(
    "Failed to stop the openproject service (exit #{result['exitcode']}).",
    'openproject/service-stop-failed',
    { 'steps' => steps }
  )
end

# 2-5. Restore tar archives.
%w[attachments configuration git_repositories svn_repositories].each do |component|
  info = files[component]
  next unless File.exist?(info['path'])

  result = run_cmd('tar', 'xzf', info['path'], '-C', info['target'])
  steps << { 'step' => "restore_#{component}", 'command' => "tar xzf #{info['path']} -C #{info['target']}" }.merge(result)
  next if result['success']

  # Attempt to restart the service before reporting the error.
  restart = run_cmd('service', 'openproject', 'restart')
  steps << { 'step' => 'restart_service_after_failure', 'command' => 'service openproject restart' }.merge(restart)
  error(
    "Failed to restore #{component} (exit #{result['exitcode']}).",
    'openproject/restore-failed',
    { 'component' => component, 'steps' => steps }
  )
end

# 6. Restore the database.
db_url_stdout, db_url_stderr, db_url_status = Open3.capture3('openproject', 'config:get', 'DATABASE_URL')
unless db_url_status.success?
  restart = run_cmd('service', 'openproject', 'restart')
  steps << { 'step' => 'restart_service_after_failure', 'command' => 'service openproject restart' }.merge(restart)
  error(
    'Failed to retrieve DATABASE_URL from openproject config.',
    'openproject/database-url-failed',
    { 'stderr' => db_url_stderr, 'steps' => steps }
  )
end
database_url = db_url_stdout.strip

pg_cmd = ['pg_restore', '--clean', '--if-exists']
pg_cmd << '--no-owner' if pg_no_owner
pg_cmd += ['--dbname', database_url, files['database']['path']]

result = run_cmd(*pg_cmd)
steps << { 'step' => 'restore_database', 'command' => pg_cmd.join(' ') }.merge(result)
unless result['success']
  restart = run_cmd('service', 'openproject', 'restart')
  steps << { 'step' => 'restart_service_after_failure', 'command' => 'service openproject restart' }.merge(restart)
  error(
    "pg_restore exited with status #{result['exitcode']}. The database may be in an inconsistent state.",
    'openproject/pg-restore-failed',
    { 'steps' => steps }
  )
end

# 7. Restart the service.
result = run_cmd('service', 'openproject', 'restart')
steps << { 'step' => 'restart_service', 'command' => 'service openproject restart' }.merge(result)
unless result['success']
  error(
    "Restore completed but failed to restart the openproject service (exit #{result['exitcode']}).",
    'openproject/service-restart-failed',
    { 'steps' => steps }
  )
end

# Build list of restored components.
restored = files.select { |_, v| File.exist?(v['path']) }.keys
skipped  = files.reject { |_, v| File.exist?(v['path']) }.keys

output = {
  'timestamp'  => timestamp,
  'backup_dir' => backup_dir,
  'restored'   => restored,
  'skipped'    => skipped,
  'steps'      => steps,
}

$stdout.puts(output.to_json)
exit 0
