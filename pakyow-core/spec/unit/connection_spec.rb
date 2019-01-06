RSpec.describe Pakyow::Connection do
  let :connection do
    Pakyow::Connection.new(nil, env)
  end

  let :env do
    Rack::MockRequest.env_for("/foo", headers: { "HTTP_REFERER" => "/bar" })
  end

  describe "#initialize" do
    it "initializes with an app and rack env"
  end

  describe "#finalize" do
    before do
      allow(connection).to receive(:set_cookies)
    end

    shared_examples "common" do
      it "sets cookies" do
        expect(connection).to receive(:set_cookies)
        connection.finalize
      end

      it "returns the response" do
        expect(connection.finalize).to be(connection.response)
      end
    end

    include_examples "common"

    context "request method is head" do
      include_examples "common"

      let :env do
        super().tap do |env|
          env["REQUEST_METHOD"] = "HEAD"
        end
      end

      it "replaces the response body with an empty array" do
        connection.response.body = ["foo"]
        expect(connection.finalize.body.length).to eq(0)
      end

      context "response body can be closed" do
        it "closes the response body" do
          output = StringIO.new("foo")
          connection.response.body = output
          expect(output).to receive(:close)
          connection.finalize
        end
      end
    end
  end

  describe "#set?" do
    context "value is set for key" do
      it "returns true"
    end

    context "value is not set for key" do
      it "returns false"
    end
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

    context "override is passed as a param" do
      context "request method is post" do
        let :env do
          Rack::MockRequest.env_for("/foo", method: :post, params: { _method: "DELETE" })
        end

        it "uses the override" do
          expect(connection.method).to eq :delete
        end
      end

      context "request method is not post" do
        let :env do
          Rack::MockRequest.env_for("/foo", method: :put, params: { _method: "DELETE" })
        end

        it "ignores the override" do
          expect(connection.method).to eq :put
        end
      end
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

    context "parsed body is set to a hash" do
      before do
        allow_any_instance_of(Rack::Request).to receive(:params).and_return(foo: :bar)
        connection.parsed_body = { baz: :qux }
      end

      it "includes the parsed body in the params" do
        expect(connection.params).to eq(foo: :bar, baz: :qux)
      end
    end

    context "parsed body is set to something other than a hash" do
      before do
        allow_any_instance_of(Rack::Request).to receive(:params).and_return(foo: :bar)
        connection.parsed_body = []
      end

      it "does not include the parsed body in the params" do
        expect(connection.params).to eq(foo: :bar)
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
    context "request format is unspecified" do
      before do
        connection.env["PATH_INFO"] = "foo"
      end

      it "returns the symbolized format" do
        expect(connection.format).to eq(:html)
      end
    end

    describe "specifying the request format through the path" do
      context "format is known" do
        before do
          connection.env["PATH_INFO"] = "foo.json"
        end

        it "returns the symbolized format" do
          expect(connection.format).to eq(:json)
        end
      end

      context "format is unknown" do
        before do
          connection.env["PATH_INFO"] = "foo.foobar"
        end

        it "returns the symbolized format" do
          expect(connection.format).to eq(:foobar)
        end
      end
    end

    describe "specifying the request format through the accept header" do
      context "format is known" do
        before do
          connection.env["ACCEPT"] = "application/json"
        end

        it "returns the symbolized format" do
          expect(connection.format).to eq(:json)
        end
      end

      context "format is unknown" do
        before do
          connection.env["ACCEPT"] = "application/foobar"
        end

        it "returns nil" do
          expect(connection.format).to eq(nil)
        end
      end

      context "format is any" do
        before do
          connection.env["ACCEPT"] = "*/*"
        end

        it "returns any" do
          expect(connection.format).to eq(:any)
        end
      end

      context "multiple formats are specified through the header" do
        before do
          connection.env["ACCEPT"] = "application/json, text/html"
        end

        it "uses the first format" do
          expect(connection.format).to eq(:json)
        end
      end
    end

    context "request format is specified in multiple ways" do
      before do
        connection.env["ACCEPT"] = "application/json"
        connection.env["PATH_INFO"] = "index.html"
      end

      it "gives precedence to the path" do
        expect(connection.format).to eq(:html)
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

  describe "#parsed_body=" do
    it "sets the parsed body" do
      connection.parsed_body = { foo: :bar }
      expect(connection.parsed_body).to eq(foo: :bar)
    end

    it "invalidates the connection params" do
      connection.params
      connection.parsed_body = { foo: :bar }
      expect(connection.params).to eq(foo: :bar)
    end
  end
end
