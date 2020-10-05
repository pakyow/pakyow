RSpec.describe Pakyow, "config.limiter" do
  describe "length" do
    subject { Pakyow.config.limiter.length }

    it "has a default value" do
      expect(subject).to eq(0)
    end
  end
end
