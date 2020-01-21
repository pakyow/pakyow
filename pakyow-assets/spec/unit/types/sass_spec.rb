require "pakyow/application/behavior/assets/types/sass"

RSpec.describe Pakyow::Application::Behavior::Assets::Types::Sass do
  require "sassc"

  let :config do
    app_class = Class.new(Pakyow::Application) do
      configurable :presenter do
        setting :path, ""
      end
    end

    app_class.include_framework :assets
    app_class.config.assets
  end

  let :local_path do
    File.expand_path("../../../support/app/frontend/assets/types-sass.sass", __FILE__)
  end

  let :klass do
    Class.new do
      def self.asset_type(type, &block)
        asset_types[type] = Class.new(Pakyow::Assets::Asset, &block)
      end

      def self.asset_types
        @asset_types ||= {}
      end

      include Pakyow::Application::Behavior::Assets::Types::Sass
    end
  end

  let :asset_type do
    klass.asset_types[:sass]
  end

  let :instance do
    asset_type.new(
      local_path: local_path,
      config: config
    )
  end

  describe "options" do
    it "sets syntax" do
      expect(::SassC::Engine).to receive(:new) do |_, options|
        @syntax = options[:syntax]
      end.and_return(double.as_null_object)
      instance.each {}

      expect(@syntax).to eq(:sass)
    end

    it "does not cache" do
      expect(::SassC::Engine).to receive(:new) do |_, options|
        @cache = options[:cache]
      end.and_return(double.as_null_object)
      instance.each {}

      expect(@cache).to eq(false)
    end

    describe "load paths" do
      before do
        expect(::SassC::Engine).to receive(:new) do |_, options|
          @load_paths = options[:load_paths]
        end.and_return(double.as_null_object)
        instance.each {}
      end

      it "includes the containing directory" do
        expect(@load_paths[0]).to eq(File.dirname(local_path))
      end

      it "includes the assets path" do
        expect(@load_paths[1]).to eq(config.path)
      end
    end
  end

  describe "dependencies" do
    it "returns sass dependency filenames" do
      engine_double = double(:engine,
        render: nil,
        dependencies: [
          double(:dependency, options: { filename: "foo" }),
          double(:dependency, options: { filename: "bar" }),
          double(:dependency, options: { filename: "baz" })
        ]
      )

      expect(::SassC::Engine).to receive(:new).and_return(engine_double)
      expect(instance.dependencies).to eq(["foo", "bar", "baz"])
    end
  end
end
