require "pakyow/security/middleware/csrf"

RSpec.describe Pakyow::Security::Middleware::CSRF do
  it "inherits base" do
    expect(Pakyow::Security::Middleware::CSRF.ancestors).to include(Pakyow::Security::Middleware::Base)
  end

  let :instance do
    Pakyow::Security::Middleware::CSRF.new(app)
  end

  let :app do
    double(:app)
  end

  context "origin header is present" do
    before do
      allow(instance).to receive(:allowed_referrer?).and_return(true)
    end

    context "origin matches request" do
      let :env do
        {
          "HTTP_ORIGIN" => "https://pakyow.com",
          "HTTP_HOST" => "pakyow.com",
          Rack::RACK_URL_SCHEME => "https",
          Rack::SERVER_PORT => 443
        }
      end

      it "allows" do
        expect(app).to receive(:call).with(env)
        instance.call(env)
      end
    end

    context "origin does not match request" do
      let :env do
        {
          "HTTP_ORIGIN" => "http://hacked.com",
          "HTTP_HOST" => "pakyow.com",
          Rack::RACK_URL_SCHEME => "https",
          Rack::SERVER_PORT => 443
        }
      end

      it "rejects" do
        expect(app).not_to receive(:call).with(env)
        expect(instance.call(env)[0]).to be(403)
      end

      context "origin is whitelisted" do
        before do
          instance.config.origin.whitelist << "http://hacked.com"
        end

        it "allows" do
          expect(app).to receive(:call).with(env)
          instance.call(env)
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
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "rejects" do
      expect(app).not_to receive(:call).with(env)
      expect(instance.call(env)[0]).to be(403)
    end
  end

  context "referrer header is present" do
    before do
      allow(instance).to receive(:allowed_origin?).and_return(true)
    end

    context "referrer matches request" do
      let :env do
        {
          "HTTP_REFERER" => "https://pakyow.com",
          "HTTP_HOST" => "pakyow.com",
          Rack::RACK_URL_SCHEME => "https",
          Rack::SERVER_PORT => 443
        }
      end

      it "allows" do
        expect(app).to receive(:call).with(env)
        instance.call(env)
      end
    end

    context "referrer does not match request" do
      let :env do
        {
          "HTTP_REFERER" => "http://hacked.com",
          "HTTP_HOST" => "pakyow.com",
          Rack::RACK_URL_SCHEME => "https",
          Rack::SERVER_PORT => 443
        }
      end

      it "rejects" do
        expect(app).not_to receive(:call).with(env)
        expect(instance.call(env)[0]).to be(403)
      end
    end
  end

  context "referrer header is missing" do
    before do
      allow(instance).to receive(:allowed_origin?).and_return(true)
    end

    let :env do
      {
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "allows" do
      expect(app).to receive(:call).with(env)
      instance.call(env)
    end

    context "referrer.allow_empty is true" do
      before do
        instance.config.referrer.allow_empty = true
      end

      it "allows" do
        expect(app).to receive(:call).with(env)
        instance.call(env)
      end
    end

    context "referrer.allow_empty is false" do
      before do
        instance.config.referrer.allow_empty = false
      end

      it "rejects" do
        expect(app).not_to receive(:call).with(env)
        expect(instance.call(env)[0]).to be(403)
      end
    end
  end

  context "origin and referrer are both valid" do
    let :env do
      {
        "HTTP_REFERER" => "https://pakyow.com",
        "HTTP_ORIGIN" => "https://pakyow.com",
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "allows" do
      expect(app).to receive(:call).with(env)
      instance.call(env)
    end
  end

  context "origin and referrer are both invalid" do
    let :env do
      {
        "HTTP_REFERER" => "http://hacked.com",
        "HTTP_ORIGIN" => "http://hacked.com",
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "rejects" do
      expect(app).not_to receive(:call).with(env)
      expect(instance.call(env)[0]).to be(403)
    end
  end

  context "origin is valid but referrer is invalid" do
    let :env do
      {
        "HTTP_REFERER" => "http://hacked.com",
        "HTTP_ORIGIN" => "https://pakyow.com",
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "rejects" do
      expect(app).not_to receive(:call).with(env)
      expect(instance.call(env)[0]).to be(403)
    end
  end

  context "referrer is valid but origin is invalid" do
    let :env do
      {
        "HTTP_REFERER" => "https://pakyow.com",
        "HTTP_ORIGIN" => "http://hacked.com",
        "HTTP_HOST" => "pakyow.com",
        Rack::RACK_URL_SCHEME => "https",
        Rack::SERVER_PORT => 443
      }
    end

    it "rejects" do
      expect(app).not_to receive(:call).with(env)
      expect(instance.call(env)[0]).to be(403)
    end
  end
end
