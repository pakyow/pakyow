require "spec_helper"
require "pakyow/realtime/connection"

describe Pakyow::Realtime::Connection do
  let :io do
    StringIO.new
  end
  
  let :version do
    1.0
  end
  
  let :key do
    Pakyow::Realtime::Connection.socket_key
  end
  
  let :connection do
    Pakyow::Realtime::Connection.new(io, version: version, key: key)
  end
  
  describe "::socket_key" do
    it "return a random value" do
      key1 = Pakyow::Realtime::Connection.socket_key
      key2 = Pakyow::Realtime::Connection.socket_key
      expect(key1).not_to eq(key2)
    end
  end
  
  describe "::socket_connection_id" do
    it "return a random value" do
      id1 = Pakyow::Realtime::Connection.socket_connection_id
      id2 = Pakyow::Realtime::Connection.socket_connection_id
      expect(id1).not_to eq(id2)
    end
  end
  
  describe "::socket_digest" do
    it "returns a unique value for a different key" do
      digest1 = Pakyow::Realtime::Connection.socket_digest("key1", "id")
      digest2 = Pakyow::Realtime::Connection.socket_digest("key2", "id")
      expect(digest1).not_to eq(digest2)
    end

    it "returns a unique value for a different connection id" do
      digest1 = Pakyow::Realtime::Connection.socket_digest("key", "id1")
      digest2 = Pakyow::Realtime::Connection.socket_digest("key", "id2")
      expect(digest1).not_to eq(digest2)
    end

    it "returns a reproducible value" do
      digest1 = Pakyow::Realtime::Connection.socket_digest("key", "id")
      digest2 = Pakyow::Realtime::Connection.socket_digest("key", "id")
      expect(digest1).to eq(digest2)
    end

    it "does not contain the orignal key or connection id" do
      digest = Pakyow::Realtime::Connection.socket_digest("key", "id")
      expect(digest).not_to include("key")
      expect(digest).not_to include("id")
    end
  end
  
  before do
    Pakyow.logger = Rack::NullLogger.new(self)
  end
  
  describe "#initialize" do
    it "creates a stream with `io` and `version`" do
      expect(connection.stream.io).to be(io)
      expect(connection.stream.version).to eq(version)
    end

    it "creates a logger" do
      expect(connection.logger.type).to eq(:sock)
      expect(connection.logger.id).to eq(key[0..7])
    end

    it "registers itself with the delegate" do
      expect(Pakyow::Realtime::Delegate.instance).to receive(:register).with(key, instance_of(Pakyow::Realtime::Connection))
      connection
    end

    it "invokes any defined `join` callbacks" do
      skip "write once Pakyow::Support::Eventable is ready"
    end
  end
  
  describe "#write" do
    let :message do
      { foo: 'bar' }
    end

    it "writes the message to the stream" do
      expect(connection.stream).to receive(:write).with(message)
      connection.write(message)
    end

    it "logs the message as verbose" do
      expect(connection.logger).to receive(:verbose).with(">> #{message}")
      connection.write(message)
    end
    
    context "and an error is raised during writing" do
      it "shuts down the connection" do
        expect(connection.stream).to receive(:write).and_raise(StandardError)
        expect(connection).to receive(:shutdown)
        connection.write(message)
      end
    end
  end
  
  describe "#receive" do
    let :data do
      :foo
    end

    it "passes the data on to the stream" do
      expect(connection.stream).to receive(:receive).with(data)
      connection.receive(data)
    end
  end
  
  describe "#shutdown" do
    it "removes itself from the connection pool" do
      expect(Pakyow::Realtime::ConnectionPool.instance).to receive(:rm).with(connection)
      connection.shutdown
    end

    it "unregisters itself from the delegate" do
      expect(Pakyow::Realtime::Delegate.instance).to receive(:unregister).with(key)
      connection.shutdown
    end

    it "invokes any defined `leave` callbacks" do
      skip "write once Pakyow::Support::Eventable is ready"
    end
    
    context "and the `io` object is a non-nil value" do
      it "closes the `io` object" do
        expect(io).to receive(:close)
        connection.shutdown
      end
    end
    
    context "and the `io` object is nil" do
      let :connection do
        Pakyow::Realtime::Connection.new(nil)
      end

      it "does not fail" do
        connection.shutdown
      end
    end
  end
  
  describe "#to_io" do
    it "returns the connection's `io` object" do
      expect(connection.to_io).to be(io)
    end
  end
end
