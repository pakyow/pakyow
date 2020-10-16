RSpec.describe "assets prelaunch commands" do
  include_context "app"

  describe "assets:precompile" do
    it "is a prelaunch command" do
      expect(Pakyow.command(:assets, :precompile).prelaunch?).to be(true)
    end

    it "is part of the build phase" do
      expect(Pakyow.command(:assets, :precompile).prelaunch_phase).to eq(:build)
    end
  end
end
