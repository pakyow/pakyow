RSpec.shared_examples :connection_type do
  let :headers do
    super().tap do |headers|
      headers["content-type"] = "text/html; charset=UTF-8"
    end
  end

  describe "#type" do
    it "returns the media type" do
      expect(connection.type).to eq("text/html")
    end

    it "is aliased as media_type" do
      expect(connection.media_type).to eq("text/html")
    end
  end

  describe "#type_params" do
    it "returns the media type params" do
      expect(connection.type_params).to eq(charset: "UTF-8")
    end

    it "is aliased as media_type_params" do
      expect(connection.media_type_params).to eq(charset: "UTF-8")
    end
  end
end
