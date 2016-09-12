require "integration/support/int_helper"

shared_examples :pushing do
  let :client do
    client = WebSocketClient.create(path: socket_connect_path)
    sleep 0.05
    client
  end
  
  let :host do
    HOST
  end
  
  let :port do
    PORT
  end
  
  let :path do
    "/push"
  end
  
  let :socket_connect_path do
    "sub/#{channel}"
  end
  
  let :params do
    { message: message, channel: channel }
  end
  
  let :channel do
    "foo_channel"
  end
  
  let :message do
    "foo_message"
  end
  
  before do
    start_server
  end

  describe "pushing a message to a channel" do
    context "when no sockets are subscribed to the channel" do
      it "succeeds without pushing the message" do
        res = HTTParty.post(File.join("http://#{host}:#{port}", path), body: params)
        expect(res.code).to be(200)
      end
    end

    context "when one socket is subscribed to the channel" do
      before do
        client
      end

      it "pushes the message to the socket" do
        res = HTTParty.post(File.join("http://#{host}:#{port}", path), body: params)
        expect(res.code).to be(200)
        sleep 0.05

        ws_message = client.messages.last
        expect(ws_message).to be_instance_of(String)

        ws_message_json = JSON.parse(ws_message)
        expect(ws_message_json["payload"]).to eq(message)
        expect(ws_message_json["channel"]).to eq(channel)
      end
    end

    context "when multiple sockets are subscribed to channels" do
      context "and both sockets are subscribed to pub channel" do
        before do
          @client1 = WebSocketClient.create(path: socket_connect_path)
          @client2 = WebSocketClient.create(path: socket_connect_path)
          sleep 0.05
          
          res = HTTParty.post(File.join("http://#{host}:#{port}", path), body: params)
          expect(res.code).to be(200)
          sleep 0.05
        end

        it "pushes the message to both sockets" do
          ws_message = @client1.messages.last
          expect(ws_message).to be_instance_of(String)
          ws_message_json = JSON.parse(ws_message)
          expect(ws_message_json["payload"]).to eq(message)
          expect(ws_message_json["channel"]).to eq(channel)
          
          ws_message = @client2.messages.last
          expect(ws_message).to be_instance_of(String)
          ws_message_json = JSON.parse(ws_message)
          expect(ws_message_json["payload"]).to eq(message)
          expect(ws_message_json["channel"]).to eq(channel)
        end
      end

      context "and one socket is not subscribed to pub channel" do
        before do
          @client1 = WebSocketClient.create(path: socket_connect_path)
          @client2 = WebSocketClient.create(path: socket_connect_path + "f")
          sleep 0.05
          
          res = HTTParty.post(File.join("http://#{host}:#{port}", path), body: params)
          expect(res.code).to be(200)
          sleep 0.05
        end

        it "pushes the message to the subscribed socket" do
          ws_message = @client1.messages.last
          expect(ws_message).to be_instance_of(String)
          ws_message_json = JSON.parse(ws_message)
          expect(ws_message_json["payload"]).to eq(message)
          expect(ws_message_json["channel"]).to eq(channel)
        end

        it "does not push the message to the non-subscribed socket" do
          ws_message = @client2.messages.last
          expect(ws_message).to be_nil
        end
      end
    end
  end
  
  describe "pushing a message to a socket" do
    context "and the socket exists" do
      before do
        client
        key = Pakyow::Realtime::Delegate.instance.connections.keys.last
        res = HTTParty.post(File.join("http://#{host}:#{port}", "push", key), body: params)
        expect(res.code).to be(200)
        sleep 0.05
      end

      it "pushes the message" do
        ws_message = client.messages.last
        expect(ws_message).to be_instance_of(String)
        ws_message_json = JSON.parse(ws_message)
        expect(ws_message_json["payload"]).to eq(message)
        expect(ws_message_json["channel"]).to eq(channel)
      end
    end
    
    context "and two sockets exist" do
      before do
        @client1 = WebSocketClient.create(path: socket_connect_path)
        @client2 = WebSocketClient.create(path: socket_connect_path)
        sleep 0.05

        key = Pakyow::Realtime::Delegate.instance.connections.keys.last
        res = HTTParty.post(File.join("http://#{host}:#{port}", "push", key), body: params)
        expect(res.code).to be(200)
        sleep 0.05
      end

      it "pushes to the correct socket" do
        ws_message = @client2.messages.last
        expect(ws_message).to be_instance_of(String)
        ws_message_json = JSON.parse(ws_message)
        expect(ws_message_json["payload"]).to eq(message)
        expect(ws_message_json["channel"]).to eq(channel)
        
        ws_message = @client1.messages.last
        expect(ws_message).to be_nil
      end
    end
  end
end

describe "pushing with SimpleRegistry" do
  before do
    Pakyow::App.config.realtime.registry = Pakyow::Realtime::SimpleRegistry
    restart_server
  end
  
  include_examples :pushing
end

if redis_available?
  describe "pushing with RedisRegistry" do
    before do
      Pakyow::App.config.realtime.registry = Pakyow::Realtime::RedisRegistry
      restart_server
    end
    
    include_examples :pushing
  end
end
