RSpec.describe Pakyow::Assets::Types::JS do
  let :config do
    app_class = Class.new(Pakyow::Application) do
      include Pakyow::Application::Config::Assets

      configurable :presenter do
        setting :path, ""
      end
    end

    app_class.config.assets.tap do |config|
      config.source_maps = false
    end
  end

  let :local_path do
    File.expand_path("../../../support/app/frontend/assets/types-js.js", __FILE__)
  end

  let :instance do
    Pakyow::Assets::Types::JS.new(
      local_path: local_path,
      config: config
    )
  end

  describe "#process" do
    let :content do
      File.read(local_path)
    end

    it "transpiles" do
      expect(Pakyow::Assets::Babel).to receive(:transform).with(
        content, **config.babel.to_h
      ).and_call_original

      instance.process(content)
    end

    it "returns the transpiled code" do
      allow(Pakyow::Assets::Babel).to receive(:transform).and_return(
        "code" => "transpiled"
      )

      expect(instance.process(content)).to eq("transpiled")
    end

    context "asset is external" do
      before do
        allow(instance).to receive(:external?).and_return(true)
      end

      it "does not transpile" do
        expect(Pakyow::Assets::Babel).not_to receive(:transform)
        instance.process(content)
      end

      it "returns the content" do
        expect(instance.process(content)).to eq(content)
      end
    end
  end
end
