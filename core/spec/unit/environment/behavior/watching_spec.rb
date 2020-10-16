RSpec.describe Pakyow::Behavior::Watching do
  describe "::ignore_changes" do
    it "pauses the watcher"

    it "yields to the passed block"
    it "resumes the watcher"

    context "block is not given" do
      it "fails"
    end

    context "something goes wrong" do
      it "resumes the watcher"
    end

    context "watcher is not initialized" do
      it "does not fail"
      it "does not yield"
    end
  end
end
