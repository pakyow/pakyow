RSpec.describe "return value from resource member definition" do
  include_context "app"

  it "returns the member" do
    expect(Pakyow.apps.first.resource(:posts, "/posts") {}.member {}.name).to eq("Test::Controllers::Posts::Member")
  end
end
