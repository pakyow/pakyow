require "pakyow/verifier"

RSpec.describe Pakyow::Verifier do
  let :result do
    verifier.call(values)
  end

  before do
    result
  end

  describe "sanitization" do
    let :verifier do
      described_class.new do
        required :foo
        optional :bar
      end
    end

    let :values do
      {
        foo: "foo",
        bar: "bar",
        baz: "baz"
      }
    end

    it "does not remove required values" do
      expect(values[:foo]).to eq("foo")
    end

    it "does not remove optional values" do
      expect(values[:bar]).to eq("bar")
    end

    it "removes values that are neither required nor optional" do
      expect(values).not_to include(:baz)
    end
  end

  describe "normalization" do
    let :verifier do
      described_class.new do
        required :foo, :datetime
      end
    end

    let :values do
      {
        foo: "2019-06-14 09:15:39 -0700"
      }
    end

    context "type is defined for a key" do
      it "typecasts the value" do
        expect(values[:foo]).to be_instance_of(Time)
      end

      it "represents the correct value" do
        expect(values[:foo].to_s).to eq("2019-06-14 09:15:39 -0700")
      end
    end
  end

  describe "verification" do
    let :verifier do
      described_class.new do
        required :foo
        optional :bar
      end
    end

    context "required value is not passed" do
      let :values do
        {
          bar: "bar"
        }
      end

      it "fails" do
        expect(result.verified?).to be(false)
      end
    end

    context "required value is passed as nil" do
      let :values do
        {
          foo: nil,
          bar: "bar"
        }
      end

      it "fails" do
        expect(result.verified?).to be(false)
      end
    end

    context "required value is passed as empty" do
      let :values do
        {
          foo: "",
          bar: "bar"
        }
      end

      it "succeeds" do
        expect(result.verified?).to be(true)
      end
    end

    context "optional value is not passed" do
      let :values do
        {
          foo: "foo"
        }
      end

      it "succeeds" do
        expect(result.verified?).to be(true)
      end
    end

    context "all values are passed" do
      let :values do
        {
          foo: "foo",
          bar: "bar"
        }
      end

      it "succeeds" do
        expect(result.verified?).to be(true)
      end
    end
  end

  describe "validation" do
    let :verifier do
      described_class.new do
        optional :foo do
          validate do |value|
            value.include?("foo")
          end

          validate do |value|
            value.include?("bar")
          end
        end
      end
    end

    context "value does not pass any validations" do
      let :values do
        {
          foo: "baz",
        }
      end

      it "fails" do
        expect(result.verified?).to be(false)
      end
    end

    context "value passes one validation but not another" do
      let :values do
        {
          foo: "foo",
        }
      end

      it "fails" do
        expect(result.verified?).to be(false)
      end
    end

    context "value passes all validations" do
      let :values do
        {
          foo: "foobar",
        }
      end

      it "succeeds" do
        expect(result.verified?).to be(true)
      end
    end

    describe "validating a value that might be false" do
      let(:verifier) {
        described_class.new do
          required :foo do
            validate do |value|
              value.is_a?(FalseClass)
            end
          end
        end
      }

      let(:values) {
        {
          foo: false,
        }
      }

      it "validates as expected" do
        expect(result.verified?).to be(true)
      end
    end
  end

  describe "messages" do
    context "verificaton failed" do
      let :verifier do
        described_class.new do
          required :foo
          required :bar
        end
      end

      let :values do
        {
          foo: "foo"
        }
      end

      it "includes a verification message for the failed key" do
        expect(result.messages[:bar]).to eq(["is required"])
      end

      it "does not include a message for values that succeeded" do
        expect(result.messages).not_to include(:foo)
      end

      context "custom message is provided" do
        let :verifier do
          described_class.new do
            required :foo, message: "custom"
          end
        end

        let :values do
          {}
        end

        it "uses the custom message" do
          expect(result.messages[:foo]).to eq(["custom"])
        end
      end
    end

    context "validation failed" do
      let :verifier do
        described_class.new do
          optional :foo do
            validate :presence
          end

          optional :bar do
            validate :presence
          end
        end
      end

      let :values do
        {
          foo: "",
          bar: "bar"
        }
      end

      it "includes a validation message for the failed key" do
        expect(result.messages[:foo]).to eq(["cannot be blank"])
      end

      it "does not include a message for values that succeeded" do
        expect(result.messages).not_to include(:bar)
      end

      context "custom message is provided" do
        let :verifier do
          described_class.new do
            optional :foo do
              validate :presence, message: "custom"
            end
          end
        end

        let :values do
          {
            foo: ""
          }
        end

        it "uses the custom message" do
          expect(result.messages[:foo]).to eq(["custom"])
        end
      end
    end

    context "verification and validation succeeded" do
      let :verifier do
        described_class.new do
          required :foo do
            validate :presence
          end
        end
      end

      let :values do
        {
          foo: "foo"
        }
      end

      it "returns an empty hash" do
        expect(result.messages).to eq({})
      end
    end
  end

  describe "full messages" do
    let :verifier do
      described_class.new do
        required :foo
        required :bar
      end
    end

    let :values do
      {
        foo: "foo"
      }
    end

    it "includes a verification message for the failed key" do
      expect(result.messages(type: :full)[:bar]).to eq(["bar is required"])
    end
  end

  describe "presentable messages" do
    let :verifier do
      described_class.new do
        required :foo
        required :bar
      end
    end

    let :values do
      {
        foo: "foo"
      }
    end

    it "includes a verification message for the failed key" do
      expect(result.messages(type: :presentable)[:bar]).to eq(["Bar is required"])
    end
  end

  describe "default values" do
    let :verifier do
      described_class.new do
        optional :foo, default: "foo"
      end
    end

    context "optional value is missing" do
      let(:values) { {} }

      it "uses the default value" do
        expect(values).to eq(foo: "foo")
      end
    end

    context "optional value is nil" do
      let(:values) { { foo: nil } }

      it "uses the default value" do
        expect(values).to eq(foo: "foo")
      end
    end

    context "optional value is provided" do
      let(:values) { { foo: "bar" } }

      it "uses the provided value" do
        expect(values).to eq(foo: "bar")
      end

      context "provided value is false" do
        let(:values) { { foo: false } }

        it "uses the provided value" do
          expect(values).to eq(foo: false)
        end
      end
    end

    context "default value is a block" do
      let :verifier do
        described_class.new do
          optional :foo, default: -> { "foo" }
        end
      end

      let(:values) { {} }

      it "resolves the default value" do
        expect(values[:foo]).to eq("foo")
      end
    end

    describe "introspecting default values" do
      let(:values) { {} }

      it "indicates there is a default value" do
        expect(verifier.default?(:foo)).to be(true)
      end

      it "fetches the default value" do
        expect(verifier.default(:foo)).to eq("foo")
      end
    end

    describe "understanding default values in the result" do
      context "default value is used" do
        let(:values) { {} }

        it "indicates the value is default" do
          expect(result.default?(:foo)).to be(true)
        end
      end

      context "default value is not used" do
        let(:values) { { foo: "bar" } }

        it "indicates the value is not a default" do
          expect(result.default?(:foo)).to be(false)
        end
      end
    end
  end
end
