require "pakyow/support/bindable"

RSpec.describe Pakyow::Bindable do
  let :instance do
    object.new
  end

  let :object do
    Class.new do
      include Pakyow::Bindable
    end
  end

  context "public method exists" do
    let :object do
      Class.new do
        include Pakyow::Bindable

        def message
          "hello"
        end
      end
    end

    describe "#include?" do
      it "returns true" do
        expect(instance.include?(:message)).to be(true)
      end
    end

    describe "#[]" do
      it "returns the value" do
        expect(instance[:message]).to eq("hello")
      end
    end
  end

  context "private method exists" do
    let :object do
      Class.new do
        include Pakyow::Bindable

        private def message
          "hello"
        end
      end
    end

    describe "#include?" do
      it "returns false" do
        expect(instance.include?(:message)).to be(false)
      end
    end

    describe "#[]" do
      it "returns nil" do
        expect(instance[:message]).to be(nil)
      end
    end
  end

  context "no method exists" do
    describe "#include?" do
      it "returns false" do
        expect(instance.include?(:message)).to be(false)
      end
    end

    describe "#[]" do
      it "returns nil" do
        expect(instance[:message]).to be(nil)
      end
    end
  end

  context "passing nil" do
    describe "#include?" do
      it "does not fail" do
        expect(instance.include?(nil)).to be(false)
      end
    end

    describe "#[]" do
      it "does not fail" do
        expect(instance[nil]).to be(nil)
      end
    end
  end
end
