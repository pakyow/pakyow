RSpec.describe Pakyow::Assets::Types::Sass do
  require "sass"

  let :config do
    app_class = Class.new(Pakyow::App) do
      include Pakyow::Assets::Behavior::Config

      settings_for :presenter do
        setting :path, ""
      end
    end

    app_class.config.assets
  end

  let :local_path do
    File.expand_path("../../../support/app/frontend/assets/types-sass.sass", __FILE__)
  end

  let :instance do
    Pakyow::Assets::Types::Sass.new(
      local_path: local_path,
      config: config
    )
  end

  describe "options" do
    it "sets syntax" do
      expect(::Sass::Engine).to receive(:new) do |_, options|
        @syntax = options[:syntax]
      end.and_return(double.as_null_object)
      instance.each

      expect(@syntax).to eq(:sass)
    end

    it "does not cache" do
      expect(::Sass::Engine).to receive(:new) do |_, options|
        @cache = options[:cache]
      end.and_return(double.as_null_object)
      instance.each

      expect(@cache).to eq(false)
    end

    describe "load paths" do
      before do
        expect(::Sass::Engine).to receive(:new) do |_, options|
          @load_paths = options[:load_paths]
        end.and_return(double.as_null_object)
        instance.each
      end

      it "includes the containing directory" do
        expect(@load_paths[0]).to eq(File.dirname(local_path))
      end

      it "includes the assets path" do
        expect(@load_paths[1]).to eq(config.frontend_assets_path)
      end
    end
  end

  describe "dependencies" do
    it "returns sass dependency filenames" do
      for_file_double = double(:for_file,
        dependencies: [
          double(:dependency, options: { filename: "foo" }),
          double(:dependency, options: { filename: "bar" }),
          double(:dependency, options: { filename: "baz" })
        ]
      )

      expect(::Sass::Engine).to receive(:for_file).and_return(for_file_double)
      expect(instance.dependencies).to eq(["foo", "bar", "baz"])
    end
  end
end
