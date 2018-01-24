require "pakyow/security/middleware/base"

RSpec.describe Pakyow::Security::Middleware::Base do
  let :instance do
    Pakyow::Security::Middleware::Base.new(app)
  end

  let :app do
    double(:app)
  end

  describe "safe methods" do
    it "allows GET" do
      env = {
        "REQUEST_METHOD" => "GET"
      }

      expect(app).to receive(:call).with(env)
      instance.call(env)
    end

    it "allows HEAD" do
      env = {
        "REQUEST_METHOD" => "HEAD"
      }

      expect(app).to receive(:call).with(env)
      instance.call(env)
    end

    it "allows OPTIONS" do
      env = {
        "REQUEST_METHOD" => "OPTIONS"
      }

      expect(app).to receive(:call).with(env)
      instance.call(env)
    end

    it "allows TRACE" do
      env = {
        "REQUEST_METHOD" => "TRACE"
      }

      expect(app).to receive(:call).with(env)
      instance.call(env)
    end
  end

  describe "unsafe methods" do
    it "rejects POST" do
      env = {
        "REQUEST_METHOD" => "POST"
      }

      expect(app).not_to receive(:call).with(env)
      expect(instance.call(env)[0]).to be(403)
    end
  end

  describe "rejecting" do
    before do
      allow(instance).to receive(:safe?).and_return(false)
      allow(instance).to receive(:allowed?).and_return(false)
    end

    it "logs the rejection" do
      logger = double(:logger)
      env = { foo: "bar", Rack::RACK_LOGGER => logger }
      expect(logger).to receive(:warn).with("Request rejected by Pakyow::Security::Middleware::Base; env: {:foo=>\"bar\", \"rack.logger\"=>#<Double :logger>}")
      instance.call(env)
    end

    it "returns 403 status" do
      expect(instance.call({})[0]).to be(403)
    end

    it "returns content-type header" do
      expect(instance.call({})[1]).to eq({ "Content-Type" => "text/plain" })
    end

    it "returns text response" do
      expect(instance.call({})[2]).to eq(["Forbidden"])
    end
  end

  context "passed config options" do
    let :configurable_instance do
      Class.new(Pakyow::Security::Middleware::Base) {
        settings_for :foo do
          setting :bar
        end
      }.new(app, foo: { bar: "baz" })
    end

    it "recursively sets passed config options" do
      expect(configurable_instance.config.foo.bar).to eq("baz")
    end
  end
end
