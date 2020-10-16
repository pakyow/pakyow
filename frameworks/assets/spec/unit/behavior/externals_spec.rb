require "pakyow/application/behavior/assets/externals"

RSpec.describe Pakyow::Application::Behavior::Assets::Externals do
  let :extended_class do
    Class.new(Pakyow::Application) do
      include Pakyow::Application::Behavior::Assets::Externals

      def self.scripts
        @scripts ||= []
      end

      def self.config
        self
      end

      def self.assets
        self
      end

      def self.externals
        self
      end
    end
  end

  describe "::external_script" do
    it "registers the external" do
      expect(Pakyow::Assets::External).to receive(:new).with(:test, version: nil, package: nil, files: nil, config: extended_class)

      extended_class.external_script :test
      expect(extended_class.scripts.count).to be(1)
    end

    context "version is passed" do
      it "registers the external" do
        expect(Pakyow::Assets::External).to receive(:new).with(:test, version: "1.0.0", package: nil, files: nil, config: extended_class)

        extended_class.external_script :test, "1.0.0"
        expect(extended_class.scripts.count).to be(1)
      end

      context "package is passed" do
        it "registers the external" do
          expect(Pakyow::Assets::External).to receive(:new).with(:test, version: "1.0.0", package: :test2, files: nil, config: extended_class)

          extended_class.external_script :test, "1.0.0", package: :test2
          expect(extended_class.scripts.count).to be(1)
        end
      end
    end

    context "package is passed" do
      it "registers the external" do
        expect(Pakyow::Assets::External).to receive(:new).with(:test, version: nil, package: :test2, files: nil, config: extended_class)

        extended_class.external_script :test, package: :test2
        expect(extended_class.scripts.count).to be(1)
      end
    end
  end
end
