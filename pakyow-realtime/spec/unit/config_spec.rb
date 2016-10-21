require 'spec_helper'
require 'pakyow/realtime/config'

RSpec.describe 'configuration' do
  before do
    Pakyow::Config.reset
  end

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

      xit 'has a default value' do
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

  describe 'env defaults' do
    context 'for development' do
      before do
        Pakyow::Config.env = :development
      end

      describe 'registry' do
        it 'is Pakyow::Realtime::SimpleRegistry' do
          expect(Pakyow::Config.realtime.registry).to eq Pakyow::Realtime::SimpleRegistry
        end
      end
    end

    context 'for production' do
      before do
        Pakyow::Config.env = :production
      end

      describe 'registry' do
        it 'is Pakyow::Realtime::RedisRegistry' do
          expect(Pakyow::Config.realtime.registry).to eq Pakyow::Realtime::RedisRegistry
        end
      end
    end
  end
end
