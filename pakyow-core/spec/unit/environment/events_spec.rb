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

    it "includes `boot`" do
      expect(Pakyow.events).to include(:boot)
    end

    it "includes `shutdown`" do
      expect(Pakyow.events).to include(:shutdown)
    end

    it "includes `run`" do
      expect(Pakyow.events).to include(:run)
    end
  end
end
