# frozen_string_literal: true

shared_context 'Debian 11' do
  let(:facts) { on_supported_os['debian-11-x86_64'] }
end

shared_context 'Debian 12' do
  let(:facts) { on_supported_os['debian-12-x86_64'] }
end

RSpec.configure do |c|
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!(100)
  end
end
