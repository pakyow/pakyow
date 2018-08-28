RSpec.describe Pakyow do
  describe "events" do
    it "includes `load`" do
      expect(Pakyow.events).to include(:load)
    end

    it "includes `configure`" do
      expect(Pakyow.events).to include(:configure)
    end

    it "includes `setup`" do
      expect(Pakyow.events).to include(:setup)
    end

    it "includes `fork`" do
      expect(Pakyow.events).to include(:fork)
    end

    it "includes `boot`" do
      expect(Pakyow.events).to include(:boot)
    end
  end
end
