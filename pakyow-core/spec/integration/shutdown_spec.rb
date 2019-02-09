RSpec.describe "shutting down the environment" do
  it "stops and waits on each container"
  it "rescues from Errno::ECHILD"
  it "removes each stopped container"

  context "in restart mode" do
    it "stops and waits on each restartable container"
    it "removes each stopped container"
    it "does not remove containers that were not stopped"
  end

  shared_examples :shutdown do
    it "shuts down"

    context "from a child process" do
      it "does not shut down"
    end
  end

  context "at exit" do
    include_examples :shutdown
  end

  context "INT" do
    include_examples :shutdown
  end

  context "TERM" do
    include_examples :shutdown
  end
end
