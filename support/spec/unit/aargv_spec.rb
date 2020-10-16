require 'pakyow/support/aargv'

RSpec.describe Pakyow::Support::Aargv do
  it "names args" do
    v1 = 'foo'
    v2 = :bar

    expected_ret = {
      str: v1,
      sym: v2,
    }

    expect(described_class.normalize([v1, v2], str: String, sym: Symbol)).to eq(expected_ret)
    expect(described_class.normalize([v2, v1], str: String, sym: Symbol)).to eq(expected_ret)
  end

  it "allows multiple types" do
    expect(described_class.normalize([:foo], arg: [String, Symbol])).to eq(arg: :foo)
    expect(described_class.normalize(["foo"], arg: [String, Symbol])).to eq(arg: "foo")
  end
end
