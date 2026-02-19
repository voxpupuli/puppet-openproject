# frozen_string_literal: true

require 'voxpupuli/acceptance/spec_helper_acceptance'

ENV['BEAKER_FACTER_FQDN'] = 'openproject.example.com'

configure_beaker(modules: :fixtures)
RSpec.configure do |c|
  c.suite_hiera = true
  c.suite_hiera_data_dir = File.join('spec', 'acceptance', 'data')
  c.suite_hiera_hierachy = [
    {
      name: 'Per-node data',
      path: 'nodes/%{facts.fqdn}.yaml',
    },
    {
      name: 'OS family data',
      path: 'os/%{facts.os.family}.yaml',
    },
    {
      name: 'Common data',
      path: 'common.yaml',
    },
  ]
end
