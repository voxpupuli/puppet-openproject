# frozen_string_literal: true

# SPDX-FileCopyrightText: 2026 Vox Pupuli
# SPDX-License-Identifier: GPL-3.0-only

require 'spec_helper'

describe 'openproject::system_requirements' do
  let(:hiera_config) { 'hiera.yaml' }
  let(:node) { 'openproject.example.com' }
  let(:pre_condition) { 'include openproject' }

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
          is_expected.to contain_class('openproject::system_requirements')
        }

        %w[
          apt-transport-https
          ca-certificates
          wget
          gpg
        ].each do |package|
          it {
            is_expected.to contain_package(package).with_ensure('installed')
          }
        end
      end

      context 'with enable_full_text_extract enabled' do
        let(:pre_condition) do
          'class { "openproject": enable_full_text_extract => true }'
        end

        it {
          is_expected.to compile.with_all_deps
        }

        %w[
          catdoc
          unrtf
          poppler-utils
          tesseract-ocr
        ].each do |package|
          it {
            is_expected.to contain_package(package).with_ensure('installed')
          }
        end
      end
    end
  end
end
