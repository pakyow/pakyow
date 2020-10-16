require "pakyow/support/object_name"

RSpec.describe Pakyow::Support::ObjectName do
  context "namespace is empty" do
    let(:object_name) {
      described_class.build(:foo)
    }

    it "builds the correct constant" do
      expect(object_name.constant).to eq("Foo")
    end
  end
end
