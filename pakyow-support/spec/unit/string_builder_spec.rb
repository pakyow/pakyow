require "pakyow/support/string_builder"

RSpec.describe Pakyow::Support::StringBuilder do
  let :builder do
    described_class.new(template)
  end

  let :template do
    "hello {foo}, it's {bar}"
  end

  it "properly builds a string from a template and values" do
    expect(
      builder.build(foo: "bob", bar: "tom")
    ).to eq("hello bob, it's tom")
  end

  context "value is nested" do
    let :template do
      "hello {foo.bar}"
    end

    it "properly builds a string from a template and values" do
      expect(
        builder.build(foo: { bar: "bob" })
      ).to eq("hello bob")
    end
  end

  context "passed a block" do
    it "fetches the value from the block" do
      expect(
        described_class.new(template) do |key|
          key.to_s.reverse
        end.build(foo: "bob", bar: "tom")
      ).to eq("hello oof, it's rab")
    end
  end

  context "value is a data proxy" do
    before do
      stub_const("Pakyow::Data::Proxy", Class.new do
        def initialize(values)
          @values = values
        end

        def one
          @values
        end
      end)
    end

    let :template do
      "hello {foo.bar}"
    end

    it "properly builds a string from the template" do
      expect(
        builder.build(foo: Pakyow::Data::Proxy.new(bar: "bob"))
      ).to eq("hello bob")
    end
  end
end
