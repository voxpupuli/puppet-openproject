# frozen_string_literal: true

require 'spec_helper'

describe 'openproject' do
  let(:hiera_config) { 'hiera.yaml' }
  let(:node) { 'openproject.example.com' }

  test_on = {
    hardwaremodels: ['x86_64'],
    supported_os: [
      {
        'operatingsystem'        => 'Debian',
        'operatingsystemrelease' => %w[11 12],
      },
    ],
  }
  on_supported_os(test_on).each do |os, os_facts|
    context 'on openproject release 14' do
      let(:params) do
        { 'release_major' => 14 }
      end

      context "on #{os}" do
        let(:facts) do
          os_facts
        end

        context 'with default params' do
          it {
            is_expected.to compile.with_all_deps
          }

          it {
            is_expected.to contain_class(
              'openproject::system_requirements'
            ).that_comes_before(
              'Class[openproject::repository]'
            )
          }

          it {
            is_expected.to contain_class(
              'openproject::repository'
            ).that_comes_before(
              'Class[openproject::install]'
            )
          }

          it {
            is_expected.to contain_class(
              'openproject::install'
            ).that_comes_before(
              'Class[openproject::configure]'
            )
          }

          it {
            is_expected.to contain_class(
              'openproject::configure'
            )
          }

          # Required Packages presence
          system_requirements_packages = %w[
            apt-transport-https
            ca-certificates
            wget
            gpg
          ]
          system_requirements_packages.each do |package|
            it {
              is_expected.to contain_package(
                package.to_s
              ).with_ensure(
                'installed'
              )
            }
          end

          # repository presence
          it {
            is_expected.to contain_apt__source(
              'openproject'
            ).with(
              'ensure' => 'present',
              'comment' => 'OpenProject APT repository - https://www.openproject.org/docs/installation-and-operations/installation/packaged/#debian-installation',
              'include' => {
                'deb' => true,
                'src' => false

              },
              'key' => {
                'name' => 'openproject.asc',
                'source' => 'https://dl.packager.io/srv/opf/openproject/key',
                'checksum' => 'sha256',
                'checksum_value' => '35ee80b7fca522dc8f418e81ff20ae189e957f0216f1e47c29cca2cd5f0069e0'
              },
              'location' => "https://dl.packager.io/srv/deb/opf/openproject/stable/#{params['release_major']}/debian",
              'release' => os_facts[:os]['distro']['release']['major'],
              'repos' => 'main'
            )
          }

          # module package presence
          it {
            is_expected.to contain_package(
              'openproject'
            ).with(
              'ensure' => 'present',
              'mark'   => 'none'
            )
          }

          # Configuration
          it {
            is_expected.to contain_file(
              '/etc/openproject'
            ).with(
              'ensure' => 'directory',
              'mode' => '0750',
              'owner' => 'openproject',
              'group' => 'openproject'
            )
          }

          # configuration - installer.dat reference file
          it {
            is_expected.to contain_file(
              '/etc/openproject/installer.dat.puppet'
            ).with(
              'ensure' => 'file',
              # rubocop:disable Layout/TrailingWhitespace
              'content' => "memcached/autoinstall install
openproject/admin_email administrator@openproject.example.com
openproject/default_language en
openproject/edition default
postgres/addon_version v1
postgres/autoinstall install
postgres/db_name openproject
postgres/db_password SuperSecretStringSuchSecure
postgres/db_username openproject
postgres/dbhost localhost
postgres/dbport 5432
postgres/retry retry
repositories/git-install skip
repositories/svn-install skip
server/autoinstall install
server/hostname openproject.example.com
server/server_path_prefix 
server/ssl no
server/variant apache2
",
              # rubocop:enable Layout/TrailingWhitespace
              'owner' => 'openproject',
              'group' => 'openproject'
            )
          }

          it {
            is_expected.to contain_exec(
              'configure openproject'
            ).with(
              'creates' => '/etc/openproject/installer.dat',
              'provider' => 'shell'
            )
          }

          it {
            is_expected.to contain_exec(
              'reconfigure openproject'
            ).with(
              'onlyif' => 'test -f /etc/openproject/installer.dat',
              'provider' => 'shell'
            )
          }
        end

        context 'With full_text_extract enabled' do
          let(:params) do
            { 'enable_full_text_extract' => true }
          end

          it {
            is_expected.to compile.with_all_deps
          }

          full_text_extract_packages = %w[
            catdoc
            unrtf
            poppler-utils
            tesseract-ocr
          ]
          full_text_extract_packages.each do |package|
            it { is_expected.to contain_package(package.to_s).with_ensure('installed') }
          end
        end

        context 'with release_major as String' do
          let(:params) do
            { 'release_major' => 'seventeen' }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects an Integer value})
          }
        end

        context 'with release_major as Boolean' do
          let(:params) do
            { 'release_major' => true }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects an Integer value})
          }
        end

        context 'with enable_full_text_extract as String' do
          let(:params) do
            { 'enable_full_text_extract' => 'yes' }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects a Boolean value})
          }
        end

        context 'with enable_full_text_extract as Integer' do
          let(:params) do
            { 'enable_full_text_extract' => 1 }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects a Boolean value})
          }
        end

        context 'on unsupported operating system' do
          let(:facts) do
            os_facts.merge(os: os_facts[:os].merge('name' => 'Ubuntu'))
          end

          it {
            is_expected.to compile.and_raise_error(%r{Unsupported Operating system!})
          }
        end

        context 'on unsupported architecture' do
          let(:facts) do
            os_facts.merge(os: os_facts[:os].merge('architecture' => 'arm64'))
          end

          it {
            is_expected.to compile.and_raise_error(%r{Unsupported hardware achitecture!})
          }
        end
      end
    end
  end
end
