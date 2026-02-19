#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

#
# openproject::backup - Bolt task
#
# Creates a full backup of an OpenProject package-based installation by running
# `openproject run backup`. The backup includes:
#
#   - PostgreSQL database dump
#   - Attachments (user-uploaded files)
#   - Configuration (/etc/openproject)
#   - Git repositories (if configured)
#   - SVN repositories (if configured)
#
# Backup files are written to /var/db/openproject/backup (default) with
# timestamped filenames.
#
# Reference: https://www.openproject.org/docs/installation-and-operations/
#            operation/backing-up/#package-based-installation-debrpm
#

require 'json'
require 'open3'
require 'set'

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

def human_size(bytes)
  units = %w[B KiB MiB GiB TiB]
  return '0 B' if bytes.zero?

  exp = (Math.log(bytes) / Math.log(1024)).to_i
  exp = units.length - 1 if exp >= units.length
  format('%.1f %s', bytes.to_f / (1024**exp), units[exp])
end

# --- main -------------------------------------------------------------------

params     = JSON.parse($stdin.read)
backup_dir = params.fetch('backup_dir', '/var/db/openproject/backup')

# Must run as root - openproject CLI requires it.
unless Process.uid.zero?
  error(
    'This task must run as root (openproject run backup requires root privileges).',
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

# Snapshot existing files before the backup so we can detect new ones.
before_files = if Dir.exist?(backup_dir)
                 Dir.glob(File.join(backup_dir, '*')).to_set
               else
                 Set.new
               end

# Run the backup.
stdout, stderr, status = Open3.capture3('openproject', 'run', 'backup')

unless status.success?
  error(
    "openproject run backup exited with status #{status.exitstatus}.",
    'openproject/backup-failed',
    {
      'exitcode' => status.exitstatus,
      'stdout'   => stdout,
      'stderr'   => stderr,
    }
  )
end

# Identify newly created backup files.
after_files = Dir.exist?(backup_dir) ? Dir.glob(File.join(backup_dir, '*')) : []
new_files   = after_files.reject { |f| before_files.include?(f) }.sort

files = new_files.map do |path|
  stat = File.stat(path)
  {
    'path'       => path,
    'name'       => File.basename(path),
    'size_bytes' => stat.size,
    'size_human' => human_size(stat.size),
  }
end

result = {
  'backup_dir'  => backup_dir,
  'files'       => files,
  'file_count'  => files.length,
  'total_bytes' => files.sum { |f| f['size_bytes'] },
  'total_human' => human_size(files.sum { |f| f['size_bytes'] }),
  'stdout'      => stdout,
}

$stdout.puts(result.to_json)
exit 0
