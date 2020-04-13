require "pakyow/application/connection"
require "pakyow/application/connection/session/cookie"

RSpec.describe Pakyow::Application::Connection::Session::Cookie do
  before do
    allow(Pakyow).to receive(:verifier).and_return(
      verifier
    )
  end

  let :verifier do
    Pakyow::Support::MessageVerifier.new("key")
  end

  let :connection do
    double(
      Pakyow::Application::Connection,
      cookies: {},
      update_request_cookie: nil
    )
  end

  let :options do
    double(
      :options,
      name: "test.session",
      domain: "pakyow.com",
      path: "/",
      max_age: "max_age",
      expires: "expires",
      secure: "secure",
      http_only: "http_only",
      same_site: "same_site"
    )
  end

  let :instance do
    described_class.new(connection, options)
  end

  let :current do
    described_class.new(connection, options)
  end

  describe "#initialize" do
    it "initializes with a connection and options" do
      expect {
        instance
      }.not_to raise_error
    end

    it "behaves like an indifferent hash" do
      instance[:foo] = "bar"
      expect(instance).to eq("foo" => "bar")
    end

    it "sets the request cookie value to the duped session object" do
      allow(connection).to receive(:update_request_cookie) do |name, update_instance|
        expect(name).to eq("test.session")
        expect(update_instance).to be_instance_of(described_class)
        update_instance[:foo] = "bar"
      end

      expect(instance).to be_empty
    end

    context "session cookie has a value" do
      before do
        current[:foo] = "bar"
        connection.cookies["test.session"] = current.to_s
      end

      it "exposes the current values" do
        expect(instance).to eq(foo: "bar")
      end

      context "session has been tampered with" do
        before do
          string = connection.cookies["test.session"]
          signed, signature = Base64.urlsafe_decode64(string).split(Pakyow::Support::MessageVerifier::JOIN_CHARACTER)
          object = Marshal.load(Base64.urlsafe_decode64(signed))
          object[:foo] = "baz"

          connection.cookies["test.session"] = Base64.urlsafe_encode64(
            Base64.urlsafe_encode64(Marshal.dump(object)) + "--#{signature}"
          )
        end

        it "resets the session" do
          expect(instance).to be_empty
        end
      end
    end
  end

  describe "#to_s" do
    before do
      instance[:foo] = "bar"
    end

    it "returns a urlsafe base64 encoded, signed, marshaled string" do
      expect(
        Marshal.load(
          verifier.verify(
            Base64.urlsafe_decode64(instance.to_s)
          )
        )
      ).to eq(foo: "bar")
    end
  end

  describe "session cookie" do
      before do
        instance
      end

      it "sets the configured domain value" do
        expect(connection.cookies["test.session"][:domain]).to eq("pakyow.com")
      end

      it "sets the configured path value" do
        expect(connection.cookies["test.session"][:path]).to eq("/")
      end

      it "sets the configured max_age value" do
        expect(connection.cookies["test.session"][:max_age]).to eq("max_age")
      end

      it "sets the configured expires value" do
        expect(connection.cookies["test.session"][:expires]).to eq("expires")
      end

      it "sets the configured secure value" do
        expect(connection.cookies["test.session"][:secure]).to eq("secure")
      end

      it "sets the configured http_only value" do
        expect(connection.cookies["test.session"][:http_only]).to eq("http_only")
      end

      it "sets the configured same_site value" do
        expect(connection.cookies["test.session"][:same_site]).to eq("same_site")
      end

      it "sets the value to self" do
        expect(connection.cookies["test.session"][:value]).to be(instance)
      end
    end
end
