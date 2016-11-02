RSpec.describe Pakyow::Request do
  include Pakyow::SpecHelpers::MockRequest

  let :request do
    mock_request(:get, "/foo", { "HTTP_REFERER" => "/bar" })
  end

  it "extends rack request" do
    expect(Pakyow::Request.superclass).to eq Rack::Request
  end

  describe "#initialization" do
    it "sets the default content type" do
      expect(request.env["CONTENT_TYPE"]).to eq("text/html")
    end
  end

  describe "#path" do
    it "returns path info" do
      expect(request.path).to eq request.path_info
    end
  end

  describe "#method" do
    it "is proper formatted" do
      expect(request.method).to eq :get
    end
  end

  describe "#params" do
    it "returns indifferentized hash" do
      expect(request.params).to be_instance_of(Pakyow::Support::IndifferentHash)
    end

    describe "the indifferent hash" do
      it "is created with params from Rack::Request" do
        params = { foo: :bar }
        allow_any_instance_of(Rack::Request).to receive(:params).and_return(params)
        expect(Pakyow::Support::IndifferentHash).to receive(:[]).with(params)
        request.params
      end
    end
  end

  describe "#cookies" do
    it "returns indifferentized hash" do
      expect(request.cookies).to be_instance_of(Pakyow::Support::IndifferentHash)
    end

    describe "the indifferent hash" do
      it "is created with cookies from Rack::Request" do
        cookies = { foo: :bar }
        allow_any_instance_of(Rack::Request).to receive(:cookies).and_return(cookies)
        expect(Pakyow::Support::IndifferentHash).to receive(:[]).with(cookies)
        request.cookies
      end
    end
  end

  describe "#format" do
    context "when content type is text/html" do
      before do
        request.env["CONTENT_TYPE"] = "text/html"
      end

      it "returns the symbolized format" do
        expect(request.format).to eq(:html)
      end
    end

    context "when content type is application/json" do
      before do
        request.env["CONTENT_TYPE"] = "application/json"
      end

      it "returns the symbolized format" do
        expect(request.format).to eq(:json)
      end
    end

    context "when content type is unknown" do
      before do
        request.env["CONTENT_TYPE"] = "foo/bar"
      end

      it "returns the symbolized format" do
        expect(request.format).to eq(nil)
      end
    end
  end
end
