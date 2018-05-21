RSpec.describe "loading the app" do
  it "loads routes from src/routes"
  it "adds src/lib to the load path"

  context "when using definition dsl" do
    it "automatically names unnamed routers"
    it "respects the given name for named routers"
    it "still allows for fully defined routers"

    describe "an automatically inferred router" do
      it "is properly namespaced"
    end
  end

  context "when not using inferred naming" do
    it "requires routers to be fully defined"
  end
end
