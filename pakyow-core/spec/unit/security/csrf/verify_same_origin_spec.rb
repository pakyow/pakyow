require "pakyow/core/security/csrf/verify_same_origin"

RSpec.describe Pakyow::Security::CSRF::VerifySameOrigin do
  it "inherits base" do
    expect(Pakyow::Security::CSRF::VerifySameOrigin.ancestors).to include(Pakyow::Security::Base)
  end

  let :instance do
    Pakyow::Security::CSRF::VerifySameOrigin.new(config)
  end

  let :config do
    {}
  end

  let :connection do
    Pakyow::Call.new(app, env)
  end

  let :app do
    double(:app)
  end

  let :env do
    {}
  end

  before do
    allow_any_instance_of(Pakyow::Security::CSRF::VerifySameOrigin).to receive(:reject) { |_, connection|
      connection.response.status = 403
    }
  end

  context "origin header is present" do
    before do
      allow(instance).to receive(:allowed_referrer?).and_return(true)
    end

    context "origin matches request" do
      let :env do
        {
          "REQUEST_METHOD" => "POST",
          "HTTP_ORIGIN" => "https://pakyow.com",
          "HTTP_HOST" => "pakyow.com",
          Rack::RACK_URL_SCHEME => "https",
          Rack::SERVER_PORT => 443
        }
      end

      it "allows" do
        expect(instance.call(connection).response.status).to be 200
      end
    end

    context "origin does not match request" do
      let :env do
        {
          "REQUEST_METHOD" => "POST",
          "HTTP_ORIGIN" => "http://hacked.com",
          "HTTP_HOST" => "pakyow.com",
          Rack::RACK_URL_SCHEME => "https",
          Rack::SERVER_PORT => 443
        }
      end

      it "rejects" do
        expect(instance.call(connection).response.status).to be 403
      end

      context "origin is whitelisted" do
        let :config do
          { origin_whitelist: ["http://hacked.com"] }
        end

        it "allows" do
          expect(instance.call(connection).response.status).to be 200
        end
      end
    end
  end

  context "origin header is missing" do
    before do
      allow(instance).to receive(:allowed_referrer?).and_return(true)
    end

    let :env do
      {
        "REQUEST_METHOD" => "POST",
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "rejects" do
      expect(instance.call(connection).response.status).to be 403
    end
  end

  context "referrer header is present" do
    before do
      allow(instance).to receive(:allowed_origin?).and_return(true)
    end

    context "referrer matches request" do
      let :env do
        {
          "REQUEST_METHOD" => "POST",
          "HTTP_REFERER" => "https://pakyow.com",
          "HTTP_HOST" => "pakyow.com",
          Rack::RACK_URL_SCHEME => "https",
          Rack::SERVER_PORT => 443
        }
      end

      it "allows" do
        expect(instance.call(connection).response.status).to be 200
      end
    end

    context "referrer does not match request" do
      let :env do
        {
          "REQUEST_METHOD" => "POST",
          "HTTP_REFERER" => "http://hacked.com",
          "HTTP_HOST" => "pakyow.com",
          Rack::RACK_URL_SCHEME => "https",
          Rack::SERVER_PORT => 443
        }
      end

      it "rejects" do
        expect(instance.call(connection).response.status).to be 403
      end
    end
  end

  context "referrer header is missing" do
    before do
      allow(instance).to receive(:allowed_origin?).and_return(true)
    end

    let :env do
      {
        "REQUEST_METHOD" => "POST",
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    context "referrer.allow_empty is true" do
      let :config do
        { allow_empty_referrer: true }
      end

      it "allows" do
        expect(instance.call(connection).response.status).to be 200
      end
    end

    context "referrer.allow_empty is false" do
      let :config do
        { allow_empty_referrer: false }
      end

      it "rejects" do
        expect(instance.call(connection).response.status).to be 403
      end
    end
  end

  context "origin and referrer are both valid" do
    let :env do
      {
        "REQUEST_METHOD" => "POST",
        "HTTP_REFERER" => "https://pakyow.com",
        "HTTP_ORIGIN" => "https://pakyow.com",
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "allows" do
      expect(instance.call(connection).response.status).to be 200
    end
  end

  context "origin and referrer are both invalid" do
    let :env do
      {
        "REQUEST_METHOD" => "POST",
        "HTTP_REFERER" => "http://hacked.com",
        "HTTP_ORIGIN" => "http://hacked.com",
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "rejects" do
      expect(instance.call(connection).response.status).to be 403
    end
  end

  context "origin is valid but referrer is invalid" do
    let :env do
      {
        "REQUEST_METHOD" => "POST",
        "HTTP_REFERER" => "http://hacked.com",
        "HTTP_ORIGIN" => "https://pakyow.com",
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "rejects" do
      expect(instance.call(connection).response.status).to be 403
    end
  end

  context "referrer is valid but origin is invalid" do
    let :env do
      {
        "REQUEST_METHOD" => "POST",
        "HTTP_REFERER" => "https://pakyow.com",
        "HTTP_ORIGIN" => "http://hacked.com",
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "rejects" do
      expect(instance.call(connection).response.status).to be 403
    end
  end
end
