require "pakyow/security/csrf/verify_same_origin"

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
    Pakyow::Connection.new(request)
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      request_scheme, request_host, request_method, "/", nil, Protocol::HTTP::Headers.new(
        [["content-type", "text/html"]].tap do |headers|
          headers << ["origin", origin] if origin
          headers << ["referer", referrer] if referrer
        end
      )
    ).tap do |request|
      request.remote_address = Addrinfo.tcp("0.0.0.0", "http")
    end
  end

  let :request_scheme do
    "https"
  end

  let :request_host do
    "pakyow.com"
  end

  let :request_method do
    "POST"
  end

  let :origin do
    nil
  end

  let :referrer do
    nil
  end

  before do
    allow_any_instance_of(Pakyow::Security::CSRF::VerifySameOrigin).to receive(:reject) { |_, connection|
      connection.status = 403
    }

    allow(Pakyow).to receive(:global_logger).and_return(
      double(:global_logger, level: 2, verbose!: nil)
    )
  end

  context "origin header is present" do
    let :origin do
      "https://pakyow.com"
    end

    context "origin matches request" do
      it "allows" do
        expect(instance.call(connection).status).to be 200
      end
    end

    context "origin scheme does not match request" do
      let :request_scheme do
        "http"
      end

      it "rejects" do
        expect(instance.call(connection).status).to be 403
      end

      context "origin is whitelisted" do
        let :config do
          { origin_whitelist: ["https://pakyow.com"] }
        end

        it "allows" do
          expect(instance.call(connection).status).to be 200
        end
      end
    end

    context "origin host does not match request" do
      let :origin do
        "https://hacked.com"
      end

      it "rejects" do
        expect(instance.call(connection).status).to be 403
      end

      context "origin is whitelisted" do
        let :config do
          { origin_whitelist: ["https://hacked.com"] }
        end

        it "allows" do
          expect(instance.call(connection).status).to be 200
        end
      end
    end

    context "origin port does not match request" do
      let :origin do
        "https://pakyow.com:4242"
      end

      it "rejects" do
        expect(instance.call(connection).status).to be 403
      end

      context "origin is whitelisted" do
        let :config do
          { origin_whitelist: ["https://pakyow.com:4242"] }
        end

        it "allows" do
          expect(instance.call(connection).status).to be 200
        end
      end
    end
  end

  context "referrer header is present" do
    let :referrer do
      "https://pakyow.com"
    end

    context "referrer matches request" do
      it "allows" do
        expect(instance.call(connection).status).to be 200
      end
    end

    context "referrer scheme does not match request" do
      let :request_scheme do
        "http"
      end

      it "rejects" do
        expect(instance.call(connection).status).to be 403
      end

      context "origin is whitelisted" do
        let :config do
          { origin_whitelist: ["https://pakyow.com"] }
        end

        it "allows" do
          expect(instance.call(connection).status).to be 200
        end
      end
    end

    context "referrer host does not match request" do
      let :referrer do
        "https://hacked.com"
      end

      it "rejects" do
        expect(instance.call(connection).status).to be 403
      end

      context "origin is whitelisted" do
        let :config do
          { origin_whitelist: ["https://hacked.com"] }
        end

        it "allows" do
          expect(instance.call(connection).status).to be 200
        end
      end
    end

    context "referrer port does not match request" do
      let :referrer do
        "https://pakyow.com:4242"
      end

      it "rejects" do
        expect(instance.call(connection).status).to be 403
      end

      context "origin is whitelisted" do
        let :config do
          { origin_whitelist: ["https://pakyow.com:4242"] }
        end

        it "allows" do
          expect(instance.call(connection).status).to be 200
        end
      end
    end
  end

  context "origin and referrer header are both missing" do
    it "rejects" do
      expect(instance.call(connection).status).to be 403
    end
  end

  context "origin and referrer are both valid" do
    let :origin do
      "https://pakyow.com"
    end

    let :referrer do
      "https://pakyow.com"
    end

    it "allows" do
      expect(instance.call(connection).status).to be 200
    end
  end

  context "origin and referrer are both invalid" do
    let :origin do
      "http://hacked.com"
    end

    let :referrer do
      "http://hacked.com"
    end

    it "rejects" do
      expect(instance.call(connection).status).to be 403
    end
  end

  context "origin is valid but referrer is invalid" do
    let :origin do
      "https://pakyow.com"
    end

    let :referrer do
      "http://hacked.com"
    end

    it "rejects" do
      expect(instance.call(connection).status).to be 403
    end
  end

  context "referrer is valid but origin is invalid" do
    let :origin do
      "http://hacked.com"
    end

    let :referrer do
      "https://pakyow.com"
    end

    it "rejects" do
      expect(instance.call(connection).status).to be 403
    end
  end
end
