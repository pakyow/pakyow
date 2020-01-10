require "pakyow/assets/babel"

RSpec.describe Pakyow::Assets::Babel do
  describe "#transform" do
    let :content do
      ""
    end

    let :options do
      {}
    end

    before do
      described_class.send(:context)
    end

    it "calls Babel.transform with content and options" do
      expect(described_class.context).to receive(:call).with(
        "Babel.transform", content, options
      )

      described_class.transform(content, **options)
    end

    it "returns the transformed content" do
      allow(described_class.context).to receive(:call).and_return("transpiled")
      expect(described_class.transform(content, **options)).to eq("transpiled")
    end

    it "only loads the execjs context once" do
      described_class.instance_variable_set(:@context, nil)
      expect(ExecJS).to receive(:compile).once.and_call_original
      described_class.transform(content, **options)
      described_class.transform(content, **options)
    end

    it "camelizes option keys" do
      expect(described_class.context).to receive(:call).with(
        "Babel.transform", content, { "fooBar" => "baz" }
      )

      described_class.transform(content, foo_bar: "baz")
    end
  end
end
