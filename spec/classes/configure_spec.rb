# frozen_string_literal: true

require 'spec_helper'

describe 'openproject::configure' do
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
      context "on #{os}" do
        let(:facts) do
          os_facts
        end

        context 'with default params' do
          it {
            is_expected.to compile.with_all_deps
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

        context 'With environment variables set' do
          let(:params) do
            { 'environment_contents' => {
              EMAIL_DELIVERY_METHOD: '"smtp"',
              SMTP_ADDRESS: '"smtp.example.com"',
              SMTP_PORT: '"587"',
              SMTP_DOMAIN: '"example.com"',
              SMTP_AUTHENTICATION: '"plain"',
              SMTP_USER_NAME: '"user"',
              SMTP_PASSWORD: '"password"',
              SMTP_ENABLE_STARTTLS_AUTO: '"true"'
            } }
          end

          it {
            is_expected.to compile.with_all_deps
          }

          # Configuration of environment variables
          it {
            is_expected.to contain_file(
              '/etc/openproject/conf.d'
            ).with(
              'ensure' => 'directory',
              'mode' => '0750',
              'owner' => 'openproject',
              'group' => 'openproject'
            )
          }

          # configuration - env
          it {
            is_expected.to contain_file(
              '/etc/openproject/conf.d/env'
            ).with(
              'ensure' => 'file',
              'content' => 'EMAIL_DELIVERY_METHOD="smtp"
SMTP_ADDRESS="smtp.example.com"
SMTP_AUTHENTICATION="plain"
SMTP_DOMAIN="example.com"
SMTP_ENABLE_STARTTLS_AUTO="true"
SMTP_PASSWORD="password"
SMTP_PORT="587"
SMTP_USER_NAME="user"
',
              'notify' => 'Exec[reconfigure openproject]',
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

        context 'with root_config_dir as relative path' do
          let(:params) do
            { 'root_config_dir' => 'etc/openproject' }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects a Stdlib::Absolutepath})
          }
        end

        context 'with root_config_dir as Integer' do
          let(:params) do
            { 'root_config_dir' => 42 }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects a Stdlib::Absolutepath})
          }
        end

        context 'with timeout as String' do
          let(:params) do
            { 'timeout' => 'slow' }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects an Integer value})
          }
        end

        context 'with installer_dat_contents as String' do
          let(:params) do
            { 'installer_dat_contents' => 'not_a_hash' }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects a Hash value})
          }
        end

        context 'with file_mode as Integer' do
          let(:params) do
            { 'file_mode' => 640 }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects a String value})
          }
        end

        context 'with logoutput as Boolean' do
          let(:params) do
            { 'logoutput' => true }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects a String value})
          }
        end

        context 'with environment_contents as String' do
          let(:params) do
            { 'environment_contents' => 'not_a_hash' }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects a value of type Undef or Hash})
          }
        end
      end
    end
  end
end
