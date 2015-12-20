shared_examples :pubsub do
  include Rack::Test::Methods
  include_examples :websocket_helpers

  let :app do
    Pakyow.app
  end

  let :key do
    socket_digest
  end

  before do
    @original_registry = Pakyow::Realtime::Delegate.instance.instance_variable_get(:@registry)
    Pakyow::Realtime::Delegate.instance.instance_variable_set(:@registry, registry)

    allow(response).to receive(:render)
    allow(WebSocket::ClientHandshake).to receive(:new).and_return(valid_handshake)
    allow_any_instance_of(Pakyow::CallContext).to receive(:socket_digest).and_return(socket_digest)

    Pakyow::App.stage
    get('/', {}, rack_env)
  end

  after do
    Pakyow::Realtime::Delegate.instance.instance_variable_set(:@registry, @original_registry)
  end

  shared_examples :subscribe do
    after do
      registry.unregister_key(key)
    end

    it 'subscribes the websocket to the channel(s)' do
      channels.each_with_index do |channel, i|
        post '/sub', { channel: channel }, rack_env_with_session
        expect(registry.channels_for_key(key)).to include(channel)
        expect(registry.channels_for_key(key).length).to eq(i + 1)
      end
    end
  end

  context 'when subscribing the websocket to a single channel' do
    let :channels do
      [:foo]
    end

    include_examples :subscribe
  end

  context 'when subscribing the websocket to multiple channels' do
    let :channels do
      [:foo, :bar]
    end

    include_examples :subscribe
  end

  describe 'publishing a message to a channel' do
    context 'when no sockets are subscribed to the channel' do
      it 'succeeds without sending the message' do
        post '/pub', { channel: 'foo', msg: 'foo_msg' }, rack_env_with_session
      end
    end

    context 'when one socket is subscribed to the channel' do
      skip
    end

    context 'when multiple sockets are subscribed to channels' do
      context 'and both sockets are subscribed to pub channel' do
        skip
      end

      context 'and one socket is not subscribed to pub channel' do
        skip
      end
    end
  end
end
