RSpec.describe "endpoint for a non resource delete" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/actions/non-resource-delete"
  end

  it "does not define an action for the source" do
    expect(scope(:post).actions).to be_empty
  end
end
