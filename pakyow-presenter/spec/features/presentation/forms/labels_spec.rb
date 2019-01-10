RSpec.describe "connecting labels to fields" do
  include_context "app"

  before do
    response = call(request_path)
    expect(response[0]).to eq(200)
    @body = response[2].body.read
  end

  let :request_path do
    "/form/labels"
  end

  let :input_id do
    @body.match(/id=\"([^\""]*)\"/).to_a[1]
  end

  let :label_for do
    @body.match(/for=\"([^\""]*)\"/).to_a[1]
  end

  it "gives the related input a unique id" do
    expect(input_id.length).to eq(8)
  end

  it "replaces the label's for attribute with the input id" do
    expect(label_for).to eq(input_id)
  end

  context "no input can be found for the label" do
    let :request_path do
      "/form/labels/no-input"
    end

    it "does not make a connection" do
      expect(input_id).to be(nil)
      expect(label_for).to eq("enabled")
    end
  end

  context "input for the label already has an id" do
    let :request_path do
      "/form/labels/existing-id"
    end

    it "does not replace the input id" do
      expect(input_id).to eq("123")
    end

    it "replaces the label's for attribute with the input id" do
      expect(label_for).to eq(input_id)
    end
  end
end
