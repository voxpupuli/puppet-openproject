# frozen_string_literal: true

# SPDX-FileCopyrightText: 2026 Vox Pupuli
# SPDX-License-Identifier: GPL-3.0-only

require 'json'
require 'open3'
require 'rbconfig'

describe 'openproject::health_check' do
  let(:task_dir) { File.expand_path('../../tasks', __dir__) }
  let(:task_script) { File.join(task_dir, 'health_check.rb') }
  let(:task_metadata) { File.join(task_dir, 'health_check.json') }

  # ---------------------------------------------------------------------------
  # Task metadata (health_check.json)
  # ---------------------------------------------------------------------------
  describe 'task metadata' do
    subject(:metadata) { JSON.parse(File.read(task_metadata)) }

    it 'is valid JSON with a description' do
      expect(metadata['description']).to be_a(String)
      expect(metadata['description']).not_to be_empty
    end

    it 'uses stdin input method' do
      expect(metadata['input_method']).to eq('stdin')
    end

    it 'defines check_type parameter as Enum with default' do
      param = metadata.dig('parameters', 'check_type')
      expect(param).not_to be_nil
      expect(param['type']).to match(%r{^Enum\[})
      expect(param['default']).to eq('default')
    end

    it 'defines base_url parameter with default' do
      param = metadata.dig('parameters', 'base_url')
      expect(param).not_to be_nil
      expect(param['default']).to eq('https://localhost')
    end

    it 'defines insecure parameter defaulting to false' do
      param = metadata.dig('parameters', 'insecure')
      expect(param).not_to be_nil
      expect(param['default']).to be false
    end

    it 'defines timeout parameter with default' do
      param = metadata.dig('parameters', 'timeout')
      expect(param).not_to be_nil
      expect(param['default']).to eq(10)
    end

    it 'requires puppet-agent' do
      reqs = metadata.dig('implementations', 0, 'requirements')
      expect(reqs).to include('puppet-agent')
    end
  end

  # ---------------------------------------------------------------------------
  # Task script (health_check.rb)
  # ---------------------------------------------------------------------------
  describe 'task script' do
    it 'has valid Ruby syntax' do
      stdout, _stderr, status = Open3.capture3(RbConfig.ruby, '-c', task_script)
      expect(status).to be_success, "Ruby syntax check failed: #{stdout}"
    end

    it 'is executable' do
      expect(File.executable?(task_script)).to be true
    end
  end
end
