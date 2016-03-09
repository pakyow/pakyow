require_relative '../../spec_helper'
require 'pakyow/core/config/session'

describe 'config.session' do
  it 'registers session config' do
    expect(Pakyow::Config.session).to be_a(Pakyow::Config)
  end

  describe 'options' do
    let :opts do
      Pakyow::Config.session
        .instance_variable_get(:@defaults)
        .instance_variable_get(:@opts)
        .keys
    end

    describe 'enabled' do
      it 'is defined' do
        expect(opts).to include(:enabled)
      end

      it 'defaults to true' do
        expect(Pakyow::Config.session.enabled).to eq(true)
      end
    end

    describe 'object' do
      it 'is defined' do
        expect(opts).to include(:object)
      end

      it 'defaults to cookie' do
        expect(Pakyow::Config.session.object).to eq(Rack::Session::Cookie)
      end
    end

    describe 'key' do
      it 'is defined' do
        expect(opts).to include(:key)
      end
    end

    describe 'secret' do
      it 'is defined' do
        expect(opts).to include(:secret)
      end

      it 'defaults to ENV[SESSION_SECRET]' do
        ENV['SESSION_SECRET'] = rand.to_s
        expect(Pakyow::Config.session.secret).to eq(ENV['SESSION_SECRET'])
      end
    end
  end
end
