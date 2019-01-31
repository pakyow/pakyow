RSpec.describe Pakyow::Assets::Babel do
  describe "#transform" do
    let :content do
      ""
    end

    let :options do
      {}
    end

    it "calls Babel.transform with content and options" do
      expect_any_instance_of(ExecJS::ExternalRuntime::Context).to receive(:call).with(
        "Babel.transform", content, options
      )

      described_class.transform(content, **options)
    end

    it "returns the transformed content" do
      allow_any_instance_of(ExecJS::ExternalRuntime::Context).to receive(:call).and_return("transpiled")
      expect(described_class.transform(content, **options)).to eq("transpiled")
    end

    it "only loads the execjs context once" do
      described_class.instance_variable_set(:@context, nil)
      expect(ExecJS).to receive(:compile).once.and_call_original
      described_class.transform(content, **options)
      described_class.transform(content, **options)
    end
  end
end
