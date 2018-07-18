RSpec.describe Pakyow::Assets::External do
  let :instance do
    described_class.new(:test, version: version, package: package, config: config)
  end

  let :name do
    :test
  end

  let :version do
    "1.0.0"
  end

  let :package do
    :test2
  end

  let :config do
    Class.new {
      def externals
        self
      end

      def asset_packs_path
        "./spec/unit/tmp/packs/vendor"
      end
    }.new
  end

  describe "initialize" do
    it "initializes with a name, version, package, and config" do
      expect(instance).to be_instance_of(described_class)
    end

    it "exposes name" do
      expect(instance.name).to be(name)
    end

    it "exposes version" do
      expect(instance.version).to be(version)
    end

    it "exposes package" do
      expect(instance.package).to be(package)
    end

    context "version is nil" do
      let :version do
        nil
      end

      it "defaults to nil" do
        expect(instance.version).to be(nil)
      end
    end

    context "package is nil" do
      let :package do
        nil
      end

      it "defaults to name" do
        expect(instance.package).to be(:test)
      end
    end
  end

  describe "exist?" do
    before do
      FileUtils.mkdir_p(config.asset_packs_path)
    end

    after do
      FileUtils.rm_r("./spec/unit/tmp")
    end

    context "pack exists" do
      before do
        FileUtils.touch(File.join(config.asset_packs_path, "test.js"))
      end

      it "returns true" do
        expect(instance.exist?).to be(true)
      end
    end

    context "versioned pack exists" do
      before do
        FileUtils.touch(File.join(config.asset_packs_path, "test@1.0.0.js"))
      end

      it "returns true" do
        expect(instance.exist?).to be(true)
      end

      context "version does not match external's version" do
        before do
          FileUtils.touch(File.join(config.asset_packs_path, "test@42.0.0.js"))
        end

        it "returns true" do
          expect(instance.exist?).to be(true)
        end
      end
    end

    context "pack does not exist" do
      it "returns false" do
        expect(instance.exist?).to be(false)
      end
    end
  end
end
