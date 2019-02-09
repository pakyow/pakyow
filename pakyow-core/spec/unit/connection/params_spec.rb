RSpec.describe Pakyow::Connection::Params do
  let :instance do
    described_class.new
  end

  it "initializes without arguments" do
    expect {
      instance
    }.not_to raise_error
  end

  it "acts like an indifferent hash" do
    instance["foo"] = :bar
    expect(instance[:foo]).to eq(:bar)
  end

  describe "#parse" do
    it "forwards to the internal query parser" do
      instance.parse("foo=bar")
      expect(instance[:foo]).to eq("bar")
    end
  end

  describe "#add" do
    it "forwards to the internal query parser" do
      instance.add("foo", :bar)
      expect(instance[:foo]).to eq(:bar)
    end
  end

  describe "#add_value_for_key" do
    it "forwards to the internal query parser" do
      instance.add_value_for_key(:bar, "foo[bar]")
      expect(instance[:foo][:bar]).to eq(:bar)
    end
  end
end
