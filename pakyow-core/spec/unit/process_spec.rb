require "pakyow/process"

RSpec.describe Pakyow::Process do
  describe "initialization" do
    context "count is not an integer" do
      it "is typecast to an integer" do
        expect(described_class.new(name: "test", count: "42").count).to eq(42)
      end
    end
  end
end
