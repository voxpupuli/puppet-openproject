# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'openproject class:' do
  context 'minimal required parameters' do
    let(:manifest) { 'include openproject' }

    it 'applies with no errors' do
      apply_manifest(manifest, catch_failures: true, debug: true)
    end

    # Known non-idempotent resources due to puppetlabs/apt keyring mtime bug:
    # - File[/etc/apt/keyrings/openproject.asc] triggers a content change on
    #   every run because the mtime in the checksum changes.
    # - Exec[apt_update] fires as a result of the keyring refresh propagation.
    #
    # related issue, PR's and discussions:
    # - https://github.com/puppetlabs/puppetlabs-apt/issues/1196
    # - https://github.com/puppetlabs/puppetlabs-apt/pull/1199
    # - https://github.com/puppetlabs/puppet/issues/9319
    it 'applies a second time without unexpected changes' do
      known_changes = [
        'Exec[apt_update]',
        'Apt::Source[openproject]',
        'Apt::Keyring[openproject.asc]',
        'File[/etc/apt/keyrings/openproject.asc]',
      ]
      result = apply_manifest(manifest, catch_failures: true, debug: true)
      changes = result.stdout.lines.
                grep(%r{Notice: /Stage\[main\]/.*changed}).
                reject { |line| known_changes.any? { |known| line.include?(known) } }
      expect(changes).to be_empty,
                         "Unexpected resource changes on second run:\n#{changes.join}"
    end

    #    describe curl_command('http://localhost/health_checks/default') do
    #      its(:response_code) { is_expected.to eq(200) }
    #      its(:exit_status) { is_expected.to eq 0 }
    #    end
  end
end
