RSpec.describe "app sessions" do
  it "exposes the session_object"
  it "exposes the session_options"

  context "sessions are disabled" do
    it "does not expose the session_object"
    it "does not expose the session_options"
  end
end
