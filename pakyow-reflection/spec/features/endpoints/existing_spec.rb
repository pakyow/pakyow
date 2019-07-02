RSpec.describe "integrating with existing endpoints" do
  context "controller exists" do
    it "adds the endpoint to the existing controller"
    it "does not create another controller"
  end

  context "route exists within existing controller" do
    it "does not override the route"
    it "exposes reflected state on the existing route"
    it "does not create another controller"
  end

  context "route exists in an unexpected controller" do
    it "does not override the route"
    it "exposes reflected state on the existing route"
    it "does not create another controller"
  end
end
