RSpec.describe Pakyow, "config.runnable.watcher" do
  describe "enabled" do
    subject { Pakyow.config.runnable.watcher.enabled }

    it "has a default value" do
      expect(subject).to be(true)
    end

    context "in production" do
      before do
        Pakyow.configure!(:production)
      end

      it "defaults to false" do
        expect(subject).to be(false)
      end
    end

    context "in ludicrous" do
      before do
        Pakyow.configure!(:ludicrous)
      end

      it "defaults to false" do
        expect(subject).to be(false)
      end
    end
  end

  describe "count" do
    subject { Pakyow.config.runnable.watcher.count }

    it "has a default value" do
      expect(subject).to eq(1)
    end

    context "watcher is not enabled" do
      before do
        Pakyow.config.runnable.watcher.enabled = false
      end

      it "is zero" do
        expect(subject).to eq(0)
      end
    end
  end
end
