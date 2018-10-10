require "pakyow/assets/behavior/externals"

RSpec.describe Pakyow::Assets::Behavior::Externals do
  let :extended_class do
    Class.new(Pakyow::App) do
      include Pakyow::Assets::Behavior::Externals

      attr_accessor :scripts

      def initialize
        @scripts = []
      end

      def config
        self
      end

      def assets
        self
      end

      def externals
        self
      end
    end
  end

  let :instance do
    extended_class.new
  end

  describe "#external_script" do
    it "registers the external" do
      expect(Pakyow::Assets::External).to receive(:new).with(:test, version: nil, package: nil, files: nil, config: instance)

      instance.external_script :test
      expect(instance.scripts.count).to be(1)
    end

    context "version is passed" do
      it "registers the external" do
        expect(Pakyow::Assets::External).to receive(:new).with(:test, version: "1.0.0", package: nil, files: nil, config: instance)

        instance.external_script :test, "1.0.0"
        expect(instance.scripts.count).to be(1)
      end

      context "package is passed" do
        it "registers the external" do
          expect(Pakyow::Assets::External).to receive(:new).with(:test, version: "1.0.0", package: :test2, files: nil, config: instance)

          instance.external_script :test, "1.0.0", package: :test2
          expect(instance.scripts.count).to be(1)
        end
      end
    end

    context "package is passed" do
      it "registers the external" do
        expect(Pakyow::Assets::External).to receive(:new).with(:test, version: nil, package: :test2, files: nil, config: instance)

        instance.external_script :test, package: :test2
        expect(instance.scripts.count).to be(1)
      end
    end
  end
end
