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

  describe "html safety" do
    it "does not make strings html safe by default" do
      expect(
        builder.build(foo: "bob", bar: "<strong>tom</strong>")
      ).to eq("hello bob, it's <strong>tom</strong>")
    end

    context "builder has html safety enabled" do
      let :builder do
        described_class.new(template, html_safe: true)
      end

      it "makes strings html safe" do
        expect(
          builder.build(foo: "bob", bar: "<strong>tom</strong>")
        ).to eq("hello bob, it's &lt;strong&gt;tom&lt;/strong&gt;")
      end
    end
  end

  context "passing a non-string template" do
    let :template do
      :foo
    end

    it "typecasts to a string" do
      expect(builder.build).to eq("foo")
    end
  end
end
