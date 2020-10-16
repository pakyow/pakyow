RSpec.describe Pakyow, "config.runnable" do
  describe "formation" do
    subject { Pakyow.config.runnable.formation }

    it "has a default value" do
      expect(subject).to be_instance_of(Pakyow::Runnable::Formation::All)
      expect(subject.service?(:all)).to be(true)
      expect(subject.count(:all)).to eq(nil)
    end
  end
end
