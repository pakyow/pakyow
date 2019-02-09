RSpec.describe "running the environment" do
  it "calls run hooks"
  it "runs each registered process in a container"
  it "registers an at exit handler"
  it "traps signals"

  context "restart mode" do
    it "runs each restartable container"
    it "does not run containers that are not restartable"
    it "does not call hooks"
    it "does not register an at exit handler"
    it "does not trap signals"
  end
end
