RSpec.describe Pakyow::Connection do
  let :connection do
    Pakyow::Connection.new(nil, Rack::MockRequest.env_for("/foo", headers: { "HTTP_REFERER" => "/bar" }))
  end

  describe "#initialize" do
    it "initializes with an app, request, and response"
  end

  describe "#processed?" do
    it "defaults to false"
  end

  describe "#processed" do
    it "marks the state as processed"
  end

  describe "#response=" do
    it "replaces the response"
  end

  describe "#set" do
    it "sets a value by key"
  end

  describe "#get" do
    it "gets a value by key"
  end

  describe "#set_cookies" do
    it "ignores cookies that already exist with the value"
    it "sets cookies that already exist, but not with the given value"
    it "sets cookies that do not already exist"
    it "deletes cookies with nil values"
    it "deletes cookies deleted from the request"

    describe "the cookie" do
      it "includes the configured cookie path"
      it "includes the configured cookie expiration"
    end
  end

  describe "#path" do
    it "returns path info" do
      expect(connection.path).to eq connection.path_info
    end
  end

  describe "#method" do
    it "is proper formatted" do
      expect(connection.method).to eq :get
    end
  end

  describe "#params" do
    it "returns indifferentized hash" do
      expect(connection.params).to be_instance_of(Pakyow::Support::IndifferentHash)
    end

    describe "the indifferent hash" do
      it "is created with params from Rack::Request" do
        params = { foo: :bar }
        allow_any_instance_of(Rack::Request).to receive(:params).and_return(params)
        expect(connection.params).to be_instance_of(Pakyow::Support::IndifferentHash)
      end

      it "is deeply indifferentized" do
        params = { foo: { deep: :bar } }
        allow_any_instance_of(Rack::Request).to receive(:params).and_return(params)
        expect(connection.params[:foo]).to be_instance_of(Pakyow::Support::IndifferentHash)
      end
    end
  end

  describe "#cookies" do
    it "returns indifferentized hash" do
      expect(connection.cookies).to be_instance_of(Pakyow::Support::IndifferentHash)
    end

    describe "the indifferent hash" do
      it "is created with cookies from Rack::Request" do
        cookies = { foo: :bar }
        allow_any_instance_of(Rack::Request).to receive(:cookies).and_return(cookies)
        expect(connection.cookies).to be_instance_of(Pakyow::Support::IndifferentHash)
      end
    end
  end

  describe "#format" do
    context "when request format is unspecified" do
      before do
        connection.env["PATH_INFO"] = "foo"
      end

      it "returns the symbolized format" do
        expect(connection.format).to eq(:html)
      end
    end

    context "when request format is json" do
      before do
        connection.env["PATH_INFO"] = "foo.json"
      end

      it "returns the symbolized format" do
        expect(connection.format).to eq(:json)
      end
    end

    context "when content type is unknown" do
      before do
        connection.env["PATH_INFO"] = "foo.foobar"
      end

      it "returns the symbolized format" do
        expect(connection.format).to eq(:foobar)
      end
    end
  end

  describe "::nice_status" do
    context "when the status is known" do
      it "returns the nice status code name" do
        expect(Pakyow::Connection.nice_status(200)).to eq("OK")
      end
    end

    context "when the status is not known" do
      it "returns ?" do
        expect(Pakyow::Connection.nice_status(-1)).to eq("?")
      end
    end
  end

  describe "::status_code" do
    context "given status is a symbolized nice name" do
      it "returns the status code for the nice name" do
        expect(Pakyow::Connection.status_code(:ok)).to eq(200)
      end
    end

    context "given status is not a symbol" do
      it "returns the status code" do
        expect(Pakyow::Connection.status_code(200)).to eq(200)
      end
    end
  end

  describe "#format=" do
    before do
      connection.format = :json
    end

    it "sets the Content-Type header" do
      expect(connection.response_header("Content-Type")).to eq("application/json")
    end
  end

  describe "#content_type" do
    before do
      connection.set_response_header("Content-Type", "foo")
    end

    it "returns the Content-Type header" do
      expect(connection.content_type).to eq("foo")
    end

    it "is aliased as #type" do
      expect(connection.type).to eq("foo")
    end
  end

  describe "#timestamp" do
    it "returns the connection creation timestamp" do
      timestamp = Time.now
      allow(Time).to receive(:now).and_return(timestamp)
      expect(connection.timestamp).to eq(timestamp)
    end
  end

  describe "#id" do
    it "returns the connection id" do
      id = "1234"
      allow(SecureRandom).to receive(:hex).with(4).and_return(id)
      expect(connection.id).to eq(id)
    end
  end
end
