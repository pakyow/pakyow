RSpec.describe "single form endpoint: nested resource list" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/forms/single-scope/nested-resource-list"
  end

  it "defines an endpoint for the view" do
    expect(mirror.endpoints.count).to eq(1)
    expect(mirror.endpoints[0].options).to eq({})
    expect(mirror.endpoints[0].view_path).to eq("/posts/comments")
  end

  it "defines an exposure for the form" do
    expect(mirror.endpoints[0].exposures.count).to eq(1)
    expect(mirror.endpoints[0].exposures[0].scope).to be(scope(:comment))
    expect(mirror.endpoints[0].exposures[0].node).to be_instance_of(StringDoc::Node)
    expect(mirror.endpoints[0].exposures[0].binding).to eq(:"comment:form")
    expect(mirror.endpoints[0].exposures[0].parent).to be(nil)
  end

  it "defines an action for the form"
end
