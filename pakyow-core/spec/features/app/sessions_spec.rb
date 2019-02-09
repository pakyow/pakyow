RSpec.describe "app sessions" do
  it "sets values on the session"
  it "reads values from the session"

  context "sessions are disabled" do
    it "does not provide a session"
  end

  context "configured session object cannot be loaded" do
    it "raises an error"
  end

  context "session is reused across apps" do
    it "allows reuse"
  end
end
