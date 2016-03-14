require_relative '../spec_helper'
require 'pakyow/realtime/registries/simple_registry'

describe Pakyow::Realtime::SimpleRegistry do
  let :registry do
    Pakyow::Realtime::SimpleRegistry
  end

  let :channels do
    [:chan1, :chan2, :chan3]
  end

  let :key do
    :ws_key
  end

  it 'is a singleton' do
    expect(registry.instance).to eq(registry.instance)
  end
  
  it 'does not propagate' do
    expect(registry.instance.propagates?).to eq(false)
  end

  describe '#channels_for_key' do
    context 'when there are channels for key' do
      before do
        registry.instance.subscribe_to_channels_for_key(channels, key)
      end

      after do
        registry.instance.unregister_key(key)
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
    end

    it 'deletes the key from channels' do
      expect(registry.instance.channels_for_key(key)).to eq(channels)
      registry.instance.unregister_key(key)
      expect(registry.instance.channels_for_key(key)).to eq([])
    end
  end

  describe '#subscribe_to_channels_for_key' do
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
