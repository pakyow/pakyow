RSpec.describe "restarting the app when files change" do
  context "trigger_restarts is enabled" do
    it "restarts when a lib file changes"
    it "restarts when a src file changes"
    it "restarts when app config changes"
    it "restarts when env config changes"
  end

  context "trigger_restarts is disabled" do
    it "does not restart when a lib file changes"
    it "does not restart when a src file changes"
    it "does not restart when app config changes"
    it "does not restart when env config changes"
  end
end
