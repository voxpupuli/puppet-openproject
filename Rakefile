# frozen_string_literal: true

# Unmanaged by modulesync — see .sync.yml for rationale.
#
# Based on modulesync 10.8.0 Rakefile template with beaker fixture wiring
# added. When the upstream Rakefile.erb gains configurable fixture support,
# this file can return to managed status by removing the unmanaged: true
# entry in .sync.yml.

begin
  require 'voxpupuli/test/rake'
rescue LoadError
  # only available if gem group test is installed
end

begin
  require 'voxpupuli/acceptance/rake'

  # Wire fixtures:prep as a prerequisite for :beaker and fixtures:clean as a
  # post-hook. This is required because spec_helper_acceptance.rb uses
  # configure_beaker(modules: :fixtures), which copies pre-populated fixture
  # modules onto the beaker hosts at suite start. Without this wiring,
  # spec/fixtures/modules is empty and beaker has no modules to install.
  #
  # The detection is defensive: the wiring only activates when
  # spec_helper_acceptance.rb actually contains 'modules: :fixtures'.
  # Modules using the modulesync default (modules: :metadata) are unaffected.
  #
  # Neither beaker-rspec, puppet_fixtures, nor voxpupuli-acceptance (tested
  # up to 4.4.0) auto-wire this dependency. The voxpupuli-acceptance README
  # confirms this is the module developer's responsibility:
  #   https://github.com/voxpupuli/voxpupuli-acceptance#fixtures
  spec_helper_acceptance = File.join(__dir__, 'spec', 'spec_helper_acceptance.rb')
  if Rake::Task.task_defined?(:beaker) &&
     File.exist?(spec_helper_acceptance) &&
     File.read(spec_helper_acceptance).match?(%r{configure_beaker\(.*modules:\s*:fixtures})
    task beaker: ['fixtures:prep']

    Rake::Task[:beaker].enhance do
      Rake::Task['fixtures:clean'].invoke
    end
  end
rescue LoadError
  # only available if gem group acceptance is installed
end

begin
  require 'voxpupuli/release/rake_tasks'
rescue LoadError
  # only available if gem group releases is installed
else
  GCGConfig.user = 'voxpupuli'
  GCGConfig.project = 'puppet-openproject'
end

desc "Run main 'test' task and report merged results to coveralls"
task test_with_coveralls: [:test] do
  if Dir.exist?(File.expand_path('../lib', __FILE__))
    require 'coveralls/rake/task'
    Coveralls::RakeTask.new
    Rake::Task['coveralls:push'].invoke
  else
    puts 'Skipping reporting to coveralls.  Module has no lib dir'
  end
end

# vim: syntax=ruby
