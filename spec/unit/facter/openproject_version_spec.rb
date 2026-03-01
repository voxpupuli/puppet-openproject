# frozen_string_literal: true

# SPDX-FileCopyrightText: 2026 Vox Pupuli
# SPDX-License-Identifier: GPL-3.0-only

require 'spec_helper'
require 'facter'

describe 'openproject_version' do
  before { Facter.clear }
  after { Facter.clear }

  context 'on Debian with dpkg-query' do
    before do
      allow(Facter::Core::Execution).to receive(:which).with('dpkg-query').and_return('/usr/bin/dpkg-query')
      allow(Facter::Core::Execution).to receive(:which).with('rpm').and_return(nil)
    end

    it 'returns the upstream version when openproject is installed' do
      allow(Facter::Core::Execution).to receive(:execute).
        with("dpkg-query -W -f '${Status} ${Version}' openproject 2>/dev/null").
        and_return('install ok installed 14.6.3-1730194473.buster')
      expect(Facter.fact(:openproject_version).value).to eq('14.6.3')
    end

    it 'returns nil when openproject is not installed' do
      allow(Facter::Core::Execution).to receive(:execute).
        with("dpkg-query -W -f '${Status} ${Version}' openproject 2>/dev/null").
        and_return('')
      expect(Facter.fact(:openproject_version).value).to be_nil
    end
  end

  context 'on RHEL with rpm' do
    before do
      allow(Facter::Core::Execution).to receive(:which).with('dpkg-query').and_return(nil)
      allow(Facter::Core::Execution).to receive(:which).with('rpm').and_return('/usr/bin/rpm')
    end

    it 'returns the version when openproject is installed' do
      allow(Facter::Core::Execution).to receive(:execute).
        with("rpm -q --qf '%{VERSION}' openproject 2>/dev/null").
        and_return('14.6.3')
      expect(Facter.fact(:openproject_version).value).to eq('14.6.3')
    end

    it 'returns nil when openproject is not installed' do
      allow(Facter::Core::Execution).to receive(:execute).
        with("rpm -q --qf '%{VERSION}' openproject 2>/dev/null").
        and_return('package openproject is not installed')
      expect(Facter.fact(:openproject_version).value).to be_nil
    end
  end

  context 'when neither dpkg-query nor rpm is available' do
    before do
      allow(Facter::Core::Execution).to receive(:which).with('dpkg-query').and_return(nil)
      allow(Facter::Core::Execution).to receive(:which).with('rpm').and_return(nil)
    end

    it 'returns nil' do
      expect(Facter.fact(:openproject_version).value).to be_nil
    end
  end
end
