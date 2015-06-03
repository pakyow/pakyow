require_relative '../spec_helper'
require 'pakyow-realtime/delegate'

describe Pakyow::Realtime::Delegate do
  let :delegate do
    Pakyow::Realtime::Delegate.instance
  end

  let :registry do
    double(Pakyow::Realtime::SimpleRegistry, instance: registry_instance,
                                             channels_for_key: channels,
                                             unregister_key: nil,
                                             subscribe_to_channels_for_key: nil,
                                             unsubscribe_to_channels_for_key: nil)
  end

  let :registry_instance do
    instance_double(Pakyow::Realtime::SimpleRegistry)
  end

  let :channels do
    [:chan1, :chan2, :chan3]
  end

  let :key do
    :ws_key
  end

  let :connection do
    double(Pakyow::Realtime::Connection, push: nil)
  end

  describe '#initialize' do
    it 'sets registry to be an instance of the configured registry' do
      expect(delegate.registry).to eq(Pakyow::Config.realtime.registry.instance)
    end
  end

  context 'when interacting with the registry' do
    before do
      delegate.instance_variable_set(:@registry, registry)
    end

    after do
      delegate.instance_variable_set(:@registry, Pakyow::Config.realtime.registry.instance)
    end

    describe '#register' do
      before do
        delegate.register(key, connection)
      end

      after do
        delegate.unregister(key)
      end

      it 'registers the connection for key' do
        expect(delegate.connections[key]).to eq(connection)
      end

      it 'registers the connection to each channel in registry for key' do
        channels.each do |channel|
          expect(delegate.channels[channel]).to include(connection)
        end
      end
    end

    describe '#unregister' do
      before do
        delegate.unregister(key)
      end

      it 'unregisters the key with the registry' do
        expect(registry).to have_received(:unregister_key).with(key)
      end

      it 'unregisters the connection' do
        expect(delegate.connections[key]).to eq(nil)
      end

      it 'unregisters the connection for each channel' do
        channels.each do |channel|
          expect(delegate.channels.fetch(channel, [])).to_not include(connection)
        end
      end
    end

    describe '#subscribe' do
      before do
        delegate.subscribe(key, channels)
      end

      it 'subscribes the registry to channels for key' do
        expect(registry).to have_received(:subscribe_to_channels_for_key).with(channels, key)
      end
    end

    describe '#unsubscribe' do
      before do
        delegate.unsubscribe(key, channels)
      end

      it 'unsubscribes the registry to channels for key' do
        expect(registry).to have_received(:unsubscribe_to_channels_for_key).with(channels, key)
      end
    end

    describe '#push' do
      before do
        delegate.register(key, connection)
        delegate.subscribe(key, channels)
      end

      after do
        delegate.unregister(key)
      end

      let :channels do
        [:chan1]
      end

      let :unsubscribed_channels do
        [:chan2, :chan3]
      end

      let :message do
        { foo: 'bar' }
      end

      it 'pushes the message down each connection registered to channels' do
        delegate.push(message, channels)
        expect(connection).to have_received(:push).with({
          payload: message,
          channel: channels[0]
        })
      end

      it 'does not push the message down to connections not registered to channels' do
        delegate.push(message, unsubscribed_channels)
        expect(connection).to_not have_received(:push)
      end
    end
  end
end
