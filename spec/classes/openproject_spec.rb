# frozen_string_literal: true

require 'spec_helper'

describe 'openproject' do
  let(:hiera_config) { 'hiera.yaml' }
  let(:node) { 'testhost.example.com' }

  test_on = {
    hardwaremodels: ['x86_64'],
    supported_os: [
      {
        'operatingsystem'        => 'Debian',
        'operatingsystemrelease' => ['11', '12'],
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
              'openproject::system_requirements',
            ).that_comes_before(
              'Class[openproject::repository]',
            )
          }
          it {
            is_expected.to contain_class(
              'openproject::repository',
            ).that_comes_before(
              'Class[openproject::install]',
            )
          }
          it {
            is_expected.to contain_class(
              'openproject::install',
            ).that_comes_before(
              'Class[openproject::configure]',
            )
          }
          it {
            is_expected.to contain_class(
              'openproject::configure',
            ).that_comes_before(
              'Class[openproject::service]',
            )
          }
          it {
            is_expected.to contain_class(
              'openproject::service',
            )
          }

          # Required Packages presence
          system_requirements_packages = [
            'apt-transport-https',
            'ca-certificates',
            'wget',
            'gpg',
          ]
          system_requirements_packages.each do |package|
            it {
              is_expected.to contain_package(
                package.to_s,
              ).with_ensure(
                'present',
              )
            }
          end

          # repository presence
          it {
            is_expected.to contain_apt__source(
              'openproject',
            ).with(
              'ensure' => 'present',
              'comment' => 'OpenProject APT repository - https://www.openproject.org/docs/installation-and-operations/installation/packaged/#debian-installation',
              'include' => {
                'deb' => true,
                'src' => false

              },
              'key' => {
                'name' => 'openproject.asc',
                'source' => 'https://dl.packager.io/srv/opf/openproject/key'
              },
              'location' => "https://dl.packager.io/srv/deb/opf/openproject/stable/#{params['release_major']}/debian",
              'release' => os_facts[:operatingsystemmajrelease].to_s,
              'repos' => 'main',
            )
          }

          # module package presence
          it {
            is_expected.to contain_package(
              'openproject',
            ).with_ensure(
              'present',
            )
          }

          # Configuration
          it {
            is_expected.to contain_file(
              '/etc/openproject',
            ).with(
              'ensure' => 'directory',
              'mode' => '0750',
            )
          }

          # configuration - installer.dat
          it {
            is_expected.to contain_file(
              '/etc/openproject/installer.dat',
            ).with(
              'ensure' => 'file',
              'content' => "memcached/autoinstall install
openproject/edition default
postgres/autoinstall reuse
postgres/db_username openproject
postgres/dbhost localhost
postgres/dbport 5432
postgres/retry retry
repositories/git-install skip
repositories/svn-install skip
server/autoinstall install
server/hostname testhost.example.com
server/server_path_prefix 
server/ssl yes
server/ssl_cert /etc/openproject/ssl/cert.pem
server/ssl_key /etc/openproject/ssl/key.pem
server/variant apache2
",
              'notify' => 'Exec[configure openproject]',
            )
          }

          it {
            is_expected.to contain_exec(
              'configure openproject',
            ).with(
              'command' => '/usr/bin/openproject configure',
              'refreshonly' => true,
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

          full_text_extract_packages = [
            'catdoc',
            'unrtf',
            'poppler-utils',
            'tesseract-ocr',
          ]
          full_text_extract_packages.each do |package|
            it { is_expected.to contain_package(package.to_s).with_ensure('present') }
          end
        end
      end
    end
  end
end
