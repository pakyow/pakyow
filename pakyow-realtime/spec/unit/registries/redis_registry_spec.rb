require 'spec_helper'
require 'pakyow/realtime/config'
require 'pakyow/realtime/registries/redis_registry'

if redis_available?
  RSpec.describe Pakyow::Realtime::RedisRegistry do
    let :registry do
      Pakyow::Realtime::RedisRegistry
    end

    let :channels do
      ['chan1', 'chan2', 'chan3']
    end

    let :key do
      :ws_key
    end

    it 'is a singleton' do
      expect(registry.instance).to eq(registry.instance)
    end

    describe '#channels_for_key' do
      context 'when there are channels for key' do
        before do
          registry.instance.subscribe_to_channels_for_key(channels, key)
        end

        after do
          registry.instance.unregister_key(key)
          registry.instance.instance_variable_set(:@subscriber, nil)
        end

        it 'returns the channels' do
          expect(registry.instance.channels_for_key(key).sort).to eq(channels.sort)
        end
      end

      context 'when there are no channels for key' do
        it 'returns an empty array' do
          expect(registry.instance.channels_for_key(:nope)).to eq([])
        end
      end
    end

    describe '#unregister_key' do
      before do
        registry.instance.subscribe_to_channels_for_key(channels, key)
      end

      after do
        registry.instance_variable_set(:@subscriber, nil)
      end

      it 'deletes the key' do
        expect(Pakyow::Realtime.redis).to receive(:del).with("#{Pakyow::Config.realtime.redis_key}:#{key}")
        registry.instance.unregister_key(key)
      end
    end

    describe '#subscribe_to_channels_for_key' do
      before do
        registry.instance.unregister_key(key)
      end

      it 'subscribes the key to the channels' do
        expect(registry.instance.channels_for_key(key)).to eq([])
        registry.instance.subscribe_to_channels_for_key(channels, key)
        expect(registry.instance.channels_for_key(key).sort).to eq(channels.sort)
      end
    end

    describe '#unsubscribe_from_channels_for_key' do
      before do
        registry.instance.subscribe_to_channels_for_key(channels, key)
      end

      it 'unsubscribes the channels for the key' do
        expect(registry.instance.channels_for_key(key).sort).to eq(channels.sort)
        registry.instance.unsubscribe_from_channels_for_key(channels, key)
        expect(registry.instance.channels_for_key(key)).to eq([])
      end
    end
  end
end
