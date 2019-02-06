RSpec.describe Pakyow::Endpoints do
  before do
    instance << Pakyow::Endpoint.new(
      name: :foo_bar,
      method: :get,
      builder: Proc.new { |**params|
        [self, params]
      }
    )
  end

  let :instance do
    described_class.new
  end

  describe "#path" do
    it "builds a path to the named endpoint" do
      expect(instance.path(:foo_bar)).to eq([self, {}])
    end

    context "passed a hash" do
      it "builds a path to the named endpoint with the values" do
        expect(instance.path(:foo_bar, foo: :bar)).to eq([self, { foo: :bar }])
      end
    end

    context "passed an object that implements to_h" do
      it "builds a path to the named endpoint with the values" do
        klass = Class.new do
          def initialize(values)
            @values = values
          end

          def to_h
            @values
          end
        end

        expect(instance.path(:foo_bar, klass.new(foo: :bar))).to eq([self, { foo: :bar }])
      end
    end

    context "endpoint isn't found" do
      it "returns nil" do
        expect(instance.path(:foo_bar_baz)).to be(nil)
      end
    end
  end

  describe "#path_to" do
    it "calls path with the right arguments" do
      expect(instance).to receive(:path).with(:foo_bar, foo: :bar)
      instance.path_to(:foo, :bar, foo: :bar)
    end
  end
end
