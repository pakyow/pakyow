RSpec.describe "reflected resource edit endpoint" do
  include_context "reflectable app"

  context "reflected action is not defined in the existing resource" do
    it "defines the reflected endpoint"
  end

  context "endpoint is defined in the existing resource that matches the reflected endpoint" do
    context "existing endpoint exposes data" do
      it "presents the data exposed by the existing endpoint"
    end

    context "existing endpoint exposes data to a variation of the binding" do
      it "presents the data exposed by the existing endpoint"
    end

    context "existing endpoint does not expose data" do
      it "calls the route"
      it "presents the data exposed by the reflection"
    end

    context "existing endpoint explicitly renders without exposing data" do
      it "presents the data exposed by the reflection"
    end
  end
end
