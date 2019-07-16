RSpec.describe Pakyow::Application do
  describe "known events" do
    it "includes `initialize`" do
      expect(Pakyow::Application.events).to include(:initialize)
    end

    it "includes `configure`" do
      expect(Pakyow::Application.events).to include(:configure)
    end

    it "includes `load`" do
      expect(Pakyow::Application.events).to include(:load)
    end

    it "includes `finalize`" do
      expect(Pakyow::Application.events).to include(:finalize)
    end

    it "includes `boot`" do
      expect(Pakyow::Application.events).to include(:boot)
    end

    it "includes `rescue`" do
      expect(Pakyow::Application.events).to include(:rescue)
    end

    it "includes `shutdown`" do
      expect(Pakyow::Application.events).to include(:shutdown)
    end
  end
end
