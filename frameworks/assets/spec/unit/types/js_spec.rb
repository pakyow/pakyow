require "pakyow/application/behavior/assets/types/js"
require "pakyow/assets/asset"

RSpec.describe Pakyow::Application::Behavior::Assets::Types::Js do
  let :config do
    app_class = Class.new(Pakyow::Application) do
      configurable :presenter do
        setting :path, ""
      end
    end

    app_class.include_framework :assets

    config = app_class.config.assets
    config.source_maps = false
    config
  end

  let :local_path do
    File.expand_path("../../../support/app/frontend/assets/types-js.js", __FILE__)
  end

  let :klass do
    Class.new do
      def self.asset_type(type, &block)
        asset_types[type] = Class.new(Pakyow::Assets::Asset, &block)
      end

      def self.asset_types
        @asset_types ||= {}
      end

      include Pakyow::Application::Behavior::Assets::Types::Js
    end
  end

  let :asset_type do
    klass.asset_types[:js]
  end

  let :instance do
    asset_type.new(
      local_path: local_path,
      config: config
    )
  end

  describe "#process" do
    let :content do
      File.read(local_path)
    end

    it "transpiles" do
      expect(Pakyow::Assets::Scripts::Babel).to receive(:transform).with(
        content, **config.babel.to_h
      ).and_call_original

      instance.process(content)
    end

    it "returns the transpiled code" do
      allow(Pakyow::Assets::Scripts::Babel).to receive(:transform).and_return(
        "code" => "transpiled"
      )

      expect(instance.process(content)).to eq("transpiled")
    end

    context "asset is external" do
      before do
        allow(instance).to receive(:external?).and_return(true)
      end

      it "does not transpile" do
        expect(Pakyow::Assets::Scripts::Babel).not_to receive(:transform)
        instance.process(content)
      end

      it "returns the content" do
        expect(instance.process(content)).to eq(content)
      end
    end
  end
end
