# frozen_string_literal: true

require 'spec_helper'

describe 'openproject::configure' do
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
              '/etc/openproject',
            ).with(
              'ensure' => 'directory',
              'mode' => '0750',
              'owner' => 'openproject',
              'group' => 'openproject',
            )
          }

          # configuration - installer.dat
          it {
            is_expected.to contain_file(
              '/etc/openproject/installer.dat',
            ).with(
              'ensure' => 'file',
              # rubocop:disable Layout/TrailingWhitespace
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
              # rubocop:enable Layout/TrailingWhitespace
              'notify' => 'Exec[configure openproject]',
              'owner' => 'openproject',
              'group' => 'openproject',
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

        context 'With environment variables set' do
          let(:params) do
            { 'environment_contents' => {
              'EMAIL_DELIVERY_METHOD': '"smtp"',
                'SMTP_ADDRESS': '"smtp.example.com"',
                'SMTP_PORT': '"587"',
                'SMTP_DOMAIN': '"example.com"',
                'SMTP_AUTHENTICATION': '"plain"',
                'SMTP_USER_NAME': '"user"',
                'SMTP_PASSWORD': '"password"',
                'SMTP_ENABLE_STARTTLS_AUTO': '"true"'
            } }
          end

          it {
            is_expected.to compile.with_all_deps
          }

          # Configuration of environment variables
          it {
            is_expected.to contain_file(
              '/etc/openproject/conf.d',
            ).with(
              'ensure' => 'directory',
              'mode' => '0750',
              'owner' => 'openproject',
              'group' => 'openproject',
            )
          }

          # configuration - env
          it {
            is_expected.to contain_file(
              '/etc/openproject/conf.d/env',
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
              'notify' => 'Exec[configure openproject]',
              'owner' => 'openproject',
              'group' => 'openproject',
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
      end
    end
  end
end
