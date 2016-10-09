require "integration/support/int_helper"
require "pakyow/support/silenceable"

RSpec.describe "connecting a websocket" do
  include Pakyow::Support::Silenceable

  before do
    start_server
  end

  let :client do
    silence_warnings do
      @client = WebSocketClient.create
      # wait for it to connect
      sleep 0.05
    end

    @client
  end

  context "and the connection is a websocket" do
    context "and the handshake is valid" do
      it "creates a connection" do
        expect(client).not_to be(nil)
      end

      it "registers the created connection" do
        expect(Pakyow::Realtime::Delegate.instance).to receive(:register).at_least(:once)
        client
      end

      context "when a `join` callback is defined" do
        before do
          joined = -> (context) { @context = context }
          Pakyow::Realtime::Connection.on :join do
            joined.call(self)
          end

          client
        end

        it "invokes the callback" do
          expect(@context).not_to be_nil
        end

        describe "the callback context" do
          it "is a `Pakyow::CallContext` instance" do
            expect(@context).to be_instance_of(Pakyow::CallContext)
          end
        end
      end
    end

    context "and the handshake is invalid" do
      it "responds as a bad request" do
        skip 'figure out how to create an invalid handshake'
      end
    end
  end
end
