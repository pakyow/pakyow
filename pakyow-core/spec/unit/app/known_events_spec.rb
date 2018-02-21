RSpec.describe Pakyow::App do
  describe "known events" do
    it "includes `initialize`" do
      expect(Pakyow::App.known_events).to include(:initialize)
    end

    it "includes `configure`" do
      expect(Pakyow::App.known_events).to include(:configure)
    end

    it "includes `load`" do
      expect(Pakyow::App.known_events).to include(:load)
    end

    it "includes `boot`" do
      expect(Pakyow::App.known_events).to include(:boot)
    end
  end
end
