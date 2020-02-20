require "pakyow/assets/pack"

RSpec.describe Pakyow::Assets::Pack do
  let :instance do
    Pakyow::Assets::Pack.new(:test, config)
  end

  let :config do
    double(prefix: "/assets", fingerprint: false)
  end

  describe "#packed" do
    context "path matches public path" do
      context "pack exists for extension" do
        before do
          instance.instance_variable_set(:@packed, { css: [:foo, :bar]})
        end

        it "returns the matching pack" do
          expect(instance.packed("/assets/packs/test.css")).to eq([:foo, :bar])
        end
      end

      context "pack does not exist for extension" do
        it "returns an empty array" do
          expect(instance.packed("/assets/packs/test.css")).to eq([])
        end
      end
    end

    context "path matches part of public path" do
      it "returns nil" do
        expect(instance.packed("/assets/packs/t.css")).to be(nil)
      end
    end

    context "path includes public path, but does not match" do
      it "returns nil" do
        expect(instance.packed("/assets/packs/test_foo.css")).to be(nil)
      end
    end

    context "path does not match public path" do
      it "returns nil" do
        expect(instance.packed("/assets/packs/foo.css")).to be(nil)
      end
    end
  end
end
