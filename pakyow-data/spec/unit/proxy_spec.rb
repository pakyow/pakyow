RSpec.describe Pakyow::Data::Proxy do
  describe "#inspect" do
    it "includes source" do
      expect(Pakyow::Data::Proxy.__inspectables).to include(:@source)
    end

    it "does not include subscribers" do
      expect(Pakyow::Data::Proxy.__inspectables).to_not include(:@subscribers)
    end

    it "does not include proxied_calls" do
      expect(Pakyow::Data::Proxy.__inspectables).to_not include(:@proxied_calls)
    end

    it "does not include subscribable" do
      expect(Pakyow::Data::Proxy.__inspectables).to_not include(:@subscribable)
    end
  end

  describe "#unsubscribe" do
    let :instance do
      Pakyow::Data::Proxy.new(double(Pakyow::Data::Sources::Relational), double(Pakyow::Data::Subscribers))
    end

    it "makes the proxy unsubscribable" do
      expect(instance.subscribable?).to be(true)
      instance.unsubscribe
      expect(instance.subscribable?).to be(false)
    end
  end
end
