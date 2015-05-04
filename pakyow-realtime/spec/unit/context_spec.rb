require 'spec_helper'
require 'pakyow-realtime/context'
require 'pakyow-realtime/helpers'

describe Pakyow::Realtime::Context do
  let :app do
    instance_double(Pakyow::App, socket_key: '123', socket_connection_id: '321', socket_digest: '123321')
  end

  let :context do
    Pakyow::Realtime::Context.new(app)
  end

  describe '#initialize' do
    it 'sets @app' do
      expect(context.instance_variable_get(:@app)).to eq(app)
    end
  end

  describe '#delegate' do
    it 'returns the delegate singleton' do
      expect(context.delegate).to eq(Pakyow::Realtime::Delegate.instance)
    end
  end

  describe '#subscribe' do
    shared_examples :subscribe do
      it 'subscribes the websocket to the channels with socket_digest' do
        expect(Pakyow::Realtime::Delegate.instance).to receive(:subscribe).with(
          app.socket_digest(app.socket_connection_id),
          passed_arg
        )

        context.subscribe(*channel_arg)
      end
    end

    context 'when called with no channels' do
      it 'raises an error' do
        expect { context.subscribe }.to raise_error(ArgumentError)
      end
    end

    context 'when called with a single channel' do
      let :channel_arg do
        :foo_channel
      end

      let :passed_arg do
        [:foo_channel]
      end

      include_examples :subscribe
    end

    context 'when called with many channels' do
      let :channel_arg do
        [:foo_channel, :bar_channel]
      end

      let :passed_arg do
        channel_arg
      end

      include_examples :subscribe
    end

    context 'when called with an array of channels' do
      let :channel_arg do
        [[:foo_channel, :bar_channel]]
      end

      let :passed_arg do
        channel_arg.flatten
      end

      include_examples :subscribe
    end
  end

  describe '#unsubscribe' do
    shared_examples :unsubscribe do
      it 'unsubscribes the websocket to the channels with socket_digest' do
        expect(Pakyow::Realtime::Delegate.instance).to receive(:unsubscribe).with(
          app.socket_digest(app.socket_connection_id),
          passed_arg
        )

        context.unsubscribe(*channel_arg)
      end
    end

    context 'when called with no channels' do
      it 'raises an error' do
        expect { context.unsubscribe }.to raise_error(ArgumentError)
      end
    end

    context 'when called with a single channel' do
      let :channel_arg do
        :foo_channel
      end

      let :passed_arg do
        [:foo_channel]
      end

      include_examples :unsubscribe
    end

    context 'when called with many channels' do
      let :channel_arg do
        [:foo_channel, :bar_channel]
      end

      let :passed_arg do
        channel_arg
      end

      include_examples :unsubscribe
    end

    context 'when called with an array of channels' do
      let :channel_arg do
        [[:foo_channel, :bar_channel]]
      end

      let :passed_arg do
        channel_arg.flatten
      end

      include_examples :unsubscribe
    end
  end

  describe '#push' do
    let :msg do
      'foo_msg'
    end

    shared_examples :push do
      it 'pushes the message down the channels' do
        expect(Pakyow::Realtime::Delegate.instance).to receive(:push).with(
          msg,
          passed_arg
        )

        context.push(msg, *channel_arg)
      end
    end

    context 'when called with no channels' do
      it 'raises an error' do
        expect { context.push(msg) }.to raise_error(ArgumentError)
      end
    end

    context 'when called with a single channel' do
      let :channel_arg do
        :foo_channel
      end

      let :passed_arg do
        [:foo_channel]
      end

      include_examples :push
    end

    context 'when called with many channels' do
      let :channel_arg do
        [:foo_channel, :bar_channel]
      end

      let :passed_arg do
        channel_arg
      end

      include_examples :push
    end

    context 'when called with an array of channels' do
      let :channel_arg do
        [[:foo_channel, :bar_channel]]
      end

      let :passed_arg do
        channel_arg.flatten
      end

      include_examples :push
    end
  end
end
