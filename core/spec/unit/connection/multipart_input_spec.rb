RSpec.describe Pakyow::Connection::MultipartInput do
  let :instance do
    described_class.new(
      filename: filename,
      headers: headers,
      type: type
    )
  end

  let :filename do
    "foo.png"
  end

  let :headers do
    { "foo" => "bar" }
  end

  let :type do
    "image/png"
  end

  it "delegates to a tempfile" do
    expect(instance.__getobj__).to be_instance_of(Tempfile)
  end

  describe "the internal tempfile" do
    it "is named appropriately" do
      basename = File.basename(instance.path)
      expect(basename).to start_with("PakyowMultipart")
      expect(basename).to end_with(".png")
    end
  end

  describe "#filename" do
    it "returns the filename" do
      expect(instance.filename).to be(filename)
    end
  end

  describe "#headers" do
    it "returns the headers" do
      expect(instance.headers).to be(headers)
    end
  end

  describe "#type" do
    it "returns the type" do
      expect(instance.type).to be(type)
    end
  end

  describe "#media_type" do
    it "returns the type" do
      expect(instance.media_type).to be(type)
    end
  end
end
