RSpec.describe "single form endpoint: resource list" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/forms/single-scope/resource-list"
  end

  it "defines an endpoint for the view" do
    expect(mirror.endpoints.count).to eq(1)
    expect(mirror.endpoints[0].options).to eq({})
    expect(mirror.endpoints[0].view_path).to eq("/posts")
  end

  it "defines an exposure for the form" do
    expect(mirror.endpoints[0].exposures.count).to eq(1)
    expect(mirror.endpoints[0].exposures[0].scope).to be(scope(:post))
    expect(mirror.endpoints[0].exposures[0].nodes.count).to eq(1)
    expect(mirror.endpoints[0].exposures[0].nodes[0]).to be_instance_of(StringDoc::Node)
    expect(mirror.endpoints[0].exposures[0].binding).to eq(:"post:form")
    expect(mirror.endpoints[0].exposures[0].parent).to be(nil)
  end

  it "defines an action for the form"
end
