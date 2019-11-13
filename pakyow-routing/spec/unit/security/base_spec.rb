require "pakyow/security/base"

RSpec.describe Pakyow::Security::Base do
  let :instance do
    Pakyow::Security::Base.new({})
  end

  let :connection do
    Pakyow::Connection.new(request)
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      "http", "localhost", request_method, "/", nil, Protocol::HTTP::Headers.new(
        [["content-type", "text/html"]]
      )
    ).tap do |request|
      request.remote_address = Addrinfo.tcp("0.0.0.0", "http")
    end
  end

  let :request_method do
    "GET"
  end

  before do
    allow(Pakyow).to receive(:output).and_return(
      double(:output, level: 2, verbose!: nil, call: nil)
    )
  end

  describe "safe methods" do
    context "method is GET" do
      it "allows" do
        instance.call(connection)
        expect(connection.status).to be(200)
        expect(connection.halted?).to be(false)
      end
    end

    context "method is HEAD" do
      let :request_method do
        "HEAD"
      end

      it "allows" do
        instance.call(connection)
        expect(connection.status).to be(200)
        expect(connection.halted?).to be(false)
      end
    end

    context "method is OPTIONS" do
      let :request_method do
        "OPTIONS"
      end

      it "allows" do
        instance.call(connection)
        expect(connection.status).to be(200)
        expect(connection.halted?).to be(false)
      end
    end

    context "method is TRACE" do
      let :request_method do
        "TRACE"
      end

      it "allows" do
        instance.call(connection)
        expect(connection.status).to be(200)
        expect(connection.halted?).to be(false)
      end
    end
  end

  describe "unsafe methods" do
    context "method is POST" do
      let :request_method do
        "POST"
      end

      it "rejects" do
        expect { instance.call(connection) }.to raise_error(Pakyow::Security::InsecureRequest)
      end
    end
  end

  describe "rejecting" do
    before do
      allow(instance).to receive(:safe?).and_return(false)
      allow(instance).to receive(:allowed?).and_return(false)
    end

    it "logs the rejection" do
      expect(connection.logger).to receive(:warn).with("Request rejected by Pakyow::Security::Base; connection: #{connection.inspect}")

      begin
        instance.call(connection)
      rescue Pakyow::Security::InsecureRequest
      end
    end

    it "sets response status" do
      begin
        instance.call(connection)
      rescue Pakyow::Security::InsecureRequest
      end

      expect(connection.status).to be(403)
    end

    it "sets response body" do
      begin
        instance.call(connection)
      rescue Pakyow::Security::InsecureRequest
      end

      expect(connection.body.read).to eq("Forbidden")
    end
  end

  context "passed config options" do
    let :config do
      {}
    end

    it "exposes the options" do
      expect(Pakyow::Security::Base.new(config).instance_variable_get(:@config)).to be(config)
    end
  end
end
