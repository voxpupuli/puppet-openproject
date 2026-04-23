# frozen_string_literal: true

# SPDX-FileCopyrightText: 2026 Vox Pupuli
# SPDX-License-Identifier: GPL-3.0-only

require 'spec_helper'

describe 'openproject::repository' do
  let(:hiera_config) { 'hiera.yaml' }
  let(:node) { 'openproject.example.com' }

  test_on = {
    hardwaremodels: ['x86_64'],
    supported_os: [
      {
        'operatingsystem'        => 'Debian',
        'operatingsystemrelease' => %w[11 12],
      },
      {
        'operatingsystem'        => 'RedHat',
        'operatingsystemrelease' => %w[9],
      },
      {
        'operatingsystem'        => 'CentOS',
        'operatingsystemrelease' => %w[9],
      },
    ],
  }
  on_supported_os(test_on).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      context 'with default params' do
        it {
          is_expected.to compile.with_all_deps
        }

        it {
          is_expected.to contain_class('openproject::repository')
        }

        if os_facts[:os]['family'] == 'Debian'
          it {
            is_expected.to contain_apt__source(
              'openproject',
            ).with(
              'ensure' => 'present',
              'comment' => 'OpenProject APT repository - https://www.openproject.org/docs/installation-and-operations/installation/packaged/#debian-installation',
              'include' => {
                'deb' => true,
                'src' => false,
              },
              'key' => {
                'name'           => 'openproject.asc',
                'source'         => 'https://dl.packager.io/srv/opf/openproject/key',
                'checksum'       => 'sha256',
                'checksum_value' => '35ee80b7fca522dc8f418e81ff20ae189e957f0216f1e47c29cca2cd5f0069e0',
              },
              'location' => 'https://dl.packager.io/srv/deb/opf/openproject/stable/17/debian',
              'release' => os_facts[:os]['distro']['release']['major'],
              'repos' => 'main',
            )
          }
        end

        if os_facts[:os]['family'] == 'RedHat'
          it {
            is_expected.to contain_yumrepo('openproject').with(
              'descr' => 'OpenProject RPM repository',
              'enabled' => 1,
              'gpgcheck' => 0,
              'repo_gpgcheck' => 1,
              'gpgkey' => 'https://dl.packager.io/srv/opf/openproject/key',
              'baseurl' => 'https://dl.packager.io/srv/rpm/opf/openproject/stable/17/el/$releasever/$basearch',
            )
          }
        end
      end

      context 'with custom release_major' do
        let(:params) do
          { 'release_major' => 14 }
        end

        it {
          is_expected.to compile.with_all_deps
        }

        if os_facts[:os]['family'] == 'Debian'
          it {
            is_expected.to contain_apt__source(
              'openproject',
            ).with(
              'location' => 'https://dl.packager.io/srv/deb/opf/openproject/stable/14/debian',
            )
          }
        end

        if os_facts[:os]['family'] == 'RedHat'
          it {
            is_expected.to contain_yumrepo('openproject').with(
              'baseurl' => 'https://dl.packager.io/srv/rpm/opf/openproject/stable/14/el/$releasever/$basearch',
            )
          }
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

      if os_facts[:os]['family'] == 'Debian'
        context 'with apt_sources as String' do
          let(:params) do
            { 'apt_sources' => 'not_a_hash' }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects a value of type Undef or Hash})
          }
        end

        context 'with apt_sources as Array' do
          let(:params) do
            { 'apt_sources' => %w[not a hash] }
          end

          it {
            is_expected.to compile.and_raise_error(%r{expects a value of type Undef or Hash})
          }
        end
      end
    end
  end
end
