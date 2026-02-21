# frozen_string_literal: true

require 'spec_helper'

describe 'openproject::install' do
  let(:hiera_config) { 'hiera.yaml' }
  let(:node) { 'openproject.example.com' }
  let(:pre_condition) { 'include openproject::repository' }

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
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      context 'with default params' do
        it {
          is_expected.to compile.with_all_deps
        }

        it {
          is_expected.to contain_package(
            'openproject'
          ).with(
            'ensure' => 'present',
            'mark'   => 'none'
          ).that_requires(
            ['Class[openproject::repository]', 'Class[apt::update]']
          )
        }
      end

      context 'with package_hold set to hold' do
        let(:params) do
          {
            'package_name'   => 'openproject-custom',
            'package_ensure' => '14.5.0-1',
            'package_hold'   => 'hold',
          }
        end

        it {
          is_expected.to compile.with_all_deps
        }

        it {
          is_expected.to contain_package(
            'openproject-custom'
          ).with(
            'ensure' => '14.5.0-1',
            'mark'   => 'hold'
          ).that_requires(
            ['Class[openproject::repository]', 'Class[apt::update]']
          )
        }
      end

      context 'with invalid package_hold value' do
        let(:params) do
          {
            'package_hold' => 'invalid',
          }
        end

        it {
          is_expected.to compile.and_raise_error(%r{expects a match for Enum\['hold', 'none'\]})
        }
      end

      context 'with package_hold as Integer' do
        let(:params) do
          {
            'package_hold' => 42,
          }
        end

        it {
          is_expected.to compile.and_raise_error(%r{expects a match for Enum\['hold', 'none'\]})
        }
      end

      context 'with package_name as Integer' do
        let(:params) do
          {
            'package_name' => 123,
          }
        end

        it {
          is_expected.to compile.and_raise_error(%r{expects a String value})
        }
      end

      context 'with package_ensure as Boolean' do
        let(:params) do
          {
            'package_ensure' => true,
          }
        end

        it {
          is_expected.to compile.and_raise_error(%r{expects a String value})
        }
      end
    end
  end
end
