require_relative '../spec_helper'
require 'pakyow/realtime/config'

describe 'configuration' do
  it 'registers realtime config' do
    expect(Pakyow::Config.realtime).to be_a(Pakyow::Config)
  end

  describe 'options' do
    let :opts do
      Pakyow::Config.realtime
        .instance_variable_get(:@defaults)
        .instance_variable_get(:@opts)
        .keys
    end

    describe 'registry' do
      it 'is defined' do
        expect(opts).to include(:registry)
      end

      it 'sets a default registry' do
        expect(Pakyow::Config.realtime.registry).to eq(Pakyow::Realtime::SimpleRegistry)
      end
    end

    describe 'redis' do
      it 'is defined' do
        expect(opts).to include(:redis)
      end
    end

    describe 'redis_key' do
      it 'is defined' do
        expect(opts).to include(:redis_key)
      end
    end
  end
end
