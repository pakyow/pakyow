RSpec.describe "restarting the environment" do
  it "shuts down in restart mode"
  it "runs in restart mode"

  context "./tmp/restart.txt changes" do
    it "restarts"

    context "./tmp/restart.txt contains an environment" do
      it "restarts in the specified environment"
      it "clears the environment from ./tmp/restart.txt"
    end
  end

  context "process stops without the environment being stopped" do
    it "restarts the process that stopped"
  end
end
