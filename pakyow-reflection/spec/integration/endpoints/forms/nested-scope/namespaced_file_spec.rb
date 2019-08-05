RSpec.describe "nested form endpoint: namespaced file" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/forms/nested-scope/namespaced-file"
  end

  it "defines an endpoint for the view" do
    expect(mirror.endpoints.count).to eq(1)
    expect(mirror.endpoints[0].options).to eq({})
    expect(mirror.endpoints[0].view_path).to eq("/foo")
  end

  it "defines an exposure for the parent scope" do
    expect(mirror.endpoints[0].exposures[0].scope).to be(scope(:post))
    expect(mirror.endpoints[0].exposures[0].nodes.count).to eq(1)
    expect(mirror.endpoints[0].exposures[0].nodes[0]).to be_instance_of(StringDoc::Node)
    expect(mirror.endpoints[0].exposures[0].binding).to eq(:post)
    expect(mirror.endpoints[0].exposures[0].parent).to be(nil)
  end

  it "defines an exposure for the form" do
    expect(mirror.endpoints[0].exposures[1].scope).to be(scope(:comment))
    expect(mirror.endpoints[0].exposures[1].nodes.count).to eq(1)
    expect(mirror.endpoints[0].exposures[1].nodes[0]).to be_instance_of(StringDoc::Node)
    expect(mirror.endpoints[0].exposures[1].binding).to eq(:"comment:form")
    expect(mirror.endpoints[0].exposures[1].parent).to be(mirror.endpoints[0].exposures[0])
  end

  it "defines an action for the form"
end
