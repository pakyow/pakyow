RSpec.describe "respawning the environment" do
  it "shuts down"
  it "replaces the process"

  context "./Gemfile.lock changes" do
    it "respawns"
  end

  context "environment config changes" do
    it "respawns"
  end

  context "./tmp/respawn.txt changes" do
    it "respawns"

    context "./tmp/respawn.txt contains an environment" do
      it "respawns in the specified environment"
    end
  end
end
