# frozen_string_literal: true

begin
  require 'voxpupuli/test/rake'
rescue LoadError
  # only available if gem group test is installed
end

begin
  require 'voxpupuli/acceptance/rake'

  # Ensure fixtures are prepared before beaker and cleaned up after a successful
  # run, but only when configure_beaker is set to use :fixtures for module
  # installation. Other modes (:metadata, nil) handle modules differently and
  # do not require fixture management.
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

# vim: syntax=ruby
