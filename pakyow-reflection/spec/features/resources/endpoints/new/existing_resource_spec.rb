RSpec.describe "reflected resource new endpoint" do
  include_context "reflectable app"

  context "reflected action is not defined in the existing resource" do
    it "defines the reflected endpoint"
  end
end
