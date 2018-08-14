require "pakyow/routing/security/base"

RSpec.describe Pakyow::Security::Base do
  let :instance do
    Pakyow::Security::Base.new({})
  end

  describe "safe methods" do
    it "allows GET" do
      connection = Pakyow::Connection.new(double("app"), "REQUEST_METHOD" => "GET")

      instance.call(connection)
      expect(connection.response.status).to be(200)
      expect(connection.halted?).to be(false)
    end

    it "allows HEAD" do
      connection = Pakyow::Connection.new(double("app"), "REQUEST_METHOD" => "HEAD")

      instance.call(connection)
      expect(connection.response.status).to be(200)
      expect(connection.halted?).to be(false)
    end

    it "allows OPTIONS" do
      connection = Pakyow::Connection.new(double("app"), "REQUEST_METHOD" => "OPTIONS")

      instance.call(connection)
      expect(connection.response.status).to be(200)
      expect(connection.halted?).to be(false)
    end

    it "allows TRACE" do
      connection = Pakyow::Connection.new(double("app"), "REQUEST_METHOD" => "TRACE")

      instance.call(connection)
      expect(connection.response.status).to be(200)
      expect(connection.halted?).to be(false)
    end
  end

  describe "unsafe methods" do
    it "rejects POST" do
      connection = Pakyow::Connection.new(double("app"), "REQUEST_METHOD" => "POST")
      expect { instance.call(connection) }.to raise_error(Pakyow::InsecureRequest)
    end
  end

  describe "rejecting" do
    before do
      allow(instance).to receive(:safe?).and_return(false)
      allow(instance).to receive(:allowed?).and_return(false)
    end

    it "logs the rejection" do
      logger = double(:logger)
      connection = Pakyow::Connection.new(double("app"), foo: "bar", Rack::RACK_LOGGER => logger)
      expect(logger).to receive(:warn).with("Request rejected by Pakyow::Security::Base; env: {:foo=>\"bar\", \"rack.logger\"=>#<Double :logger>, \"rack.request.cookie_hash\"=>{}}")

      begin
        instance.call(connection)
      rescue Pakyow::InsecureRequest
      end
    end

    it "sets response status" do
      connection = Pakyow::Connection.new(double("app"), {})

      begin
        instance.call(connection)
      rescue Pakyow::InsecureRequest
      end

      expect(connection.response.status).to be(403)
    end

    it "sets content-type header" do
      connection = Pakyow::Connection.new(double("app"), {})

      begin
        instance.call(connection)
      rescue Pakyow::InsecureRequest
      end

      expect(connection.response["Content-Type"]).to eq("text/plain")
    end

    it "sets response body" do
      connection = Pakyow::Connection.new(double("app"), {})

      begin
        instance.call(connection)
      rescue Pakyow::InsecureRequest
      end

      expect(connection.response.body).to eq(["Forbidden"])
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
