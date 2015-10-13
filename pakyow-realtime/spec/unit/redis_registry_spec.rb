require_relative '../spec_helper'
require 'pakyow-realtime/config'
require 'pakyow-realtime/registries/redis_registry'

if redis_available?
  describe Pakyow::Realtime::RedisRegistry do
    let :registry do
      Pakyow::Realtime::RedisRegistry
    end

    let :channels do
      [:chan1, :chan2, :chan3]
    end

    let :key do
      :ws_key
    end

    let :redis do
      double(Redis, hdel: nil)
    end

    it 'is a singleton' do
      expect(registry.instance).to eq(registry.instance)
    end

    it 'propagates' do
      expect(registry.instance.propagates?).to eq(true)
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
          expect(registry.instance.channels_for_key(key)).to eq(channels)
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

        @original_redis = registry.instance.instance_variable_get(:@redis)
        registry.instance.instance_variable_set(:@redis, redis)
      end

      after do
        registry.instance.instance_variable_set(:@redis, @original_redis)
        registry.instance.unregister_key(key)
        registry.instance.instance_variable_set(:@subscriber, nil)
      end

      it 'deletes the key' do
        registry.instance.unregister_key(key)
        expect(redis).to have_received(:hdel).with(Pakyow::Config.realtime.redis_key, key)
      end
    end

    describe '#subscribe_to_channels_for_key' do
      before do
        registry.instance.unregister_key(key)
      end

      it 'subscribes the key to the channels' do
        expect(registry.instance.channels_for_key(key)).to eq([])
        registry.instance.subscribe_to_channels_for_key(channels, key)
        expect(registry.instance.channels_for_key(key)).to eq(channels)
      end
    end

    describe '#unsubscribe_to_channels_for_key' do
      before do
        registry.instance.subscribe_to_channels_for_key(channels, key)
      end

      it 'unsubscribes the channels for the key' do
        expect(registry.instance.channels_for_key(key)).to eq(channels)
        registry.instance.unsubscribe_to_channels_for_key(channels, key)
        expect(registry.instance.channels_for_key(key)).to eq([])
      end
    end
  end
end
