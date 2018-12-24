RSpec.describe Pakyow::App do
  describe "known events" do
    it "includes `initialize`" do
      expect(Pakyow::App.events).to include(:initialize)
    end

    it "includes `configure`" do
      expect(Pakyow::App.events).to include(:configure)
    end

    it "includes `load`" do
      expect(Pakyow::App.events).to include(:load)
    end

    it "includes `finalize`" do
      expect(Pakyow::App.events).to include(:finalize)
    end

    it "includes `boot`" do
      expect(Pakyow::App.events).to include(:boot)
    end

    it "includes `fork`" do
      expect(Pakyow::App.events).to include(:fork)
    end

    it "includes `rescue`" do
      expect(Pakyow::App.events).to include(:rescue)
    end

    it "includes `shutdown`" do
      expect(Pakyow::App.events).to include(:shutdown)
    end
  end
end
