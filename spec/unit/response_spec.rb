RSpec.describe Pakyow::Response do
  let :response do
    Pakyow::Response.new
  end

  it "extends rack response" do
    expect(Pakyow::Response.superclass).to eq Rack::Response
  end

  describe ".nice_status" do
    context "when the status is known" do
      it "returns the nice status code name" do
        expect(Pakyow::Response.nice_status(200)).to eq("OK")
      end
    end

    context "when the status is not known" do
      it "returns ?" do
        expect(Pakyow::Response.nice_status(-1)).to eq("?")
      end
    end
  end

  describe "#format=" do
    before do
      response.format = :json
    end

    it "sets the Content-Type header" do
      expect(response["Content-Type"]).to eq("application/json")
    end
  end

  describe "#content_type" do
    before do
      response["Content-Type"] = "foo"
    end

    it "returns the Content-Type header" do
      expect(response.content_type).to eq("foo")
    end

    it "is aliased as #type" do
      expect(response.type).to eq("foo")
    end
  end
end
