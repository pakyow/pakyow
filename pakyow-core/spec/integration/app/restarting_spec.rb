RSpec.describe "restarting the app when files change" do
  context "app is restartable" do
    it "restarts when a lib file changes"
    it "restarts when a src file changes"
    it "restarts when app config changes"
    it "restarts when env config changes"
  end

  context "app is not restartable" do
    it "does not restart when a lib file changes"
    it "does not restart when a src file changes"
    it "does not restart when app config changes"
    it "does not restart when env config changes"
  end
end
