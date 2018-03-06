RSpec.describe Pakyow::Data::Proxy do
  describe "#inspect" do
    it "includes model" do
      expect(Pakyow::Data::Proxy.__inspectables).to include(:@model)
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
end
