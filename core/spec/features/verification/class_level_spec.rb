require "pakyow/behavior/verification"

RSpec.describe "defining and using class-level verifiers" do
  let(:verifiable) {
    Class.new do
      include Pakyow::Behavior::Verification

      verify do
        optional :foo
        optional :baz
      end

      verify :other do
        optional :bar
        optional :qux
      end
    end
  }

  let(:target) {
    verifiable.new
  }

  describe "default verifier" do
    context "verifiable object is not defined" do
      context "values are passed" do
        let(:values) {
          {
            foo: "foo",
            bar: "bar",
          }
        }

        before do
          target.verify values
        end

        it "verifies the passed values" do
          expect(values).to eq(foo: "foo")
        end
      end

      context "values are not passed" do
        it "raises an error" do
          expect {
            target.verify
          }.to raise_error(RuntimeError) do |error|
            expect(error.message).to eq("Expected values to be passed")
          end
        end
      end
    end

    context "verifiable object is defined" do
      let(:params) {
        {
          baz: "baz",
          qux: "qux"
        }
      }

      before do
        local = self
        verifiable.class_eval do
          define_method :params do
            local.params
          end
        end

        verifiable.verifies :params
      end

      context "values are passed" do
        let(:values) {
          {
            foo: "foo",
            bar: "bar",
          }
        }

        before do
          target.verify values
        end

        it "verifies the passed values" do
          expect(values).to eq(foo: "foo")
        end

        it "does not verify the verifiable object" do
          expect(params).to eq(baz: "baz", qux: "qux")
        end
      end

      context "values are not passed" do
        before do
          target.verify
        end

        it "verifies the verifiable object" do
          expect(params).to eq(baz: "baz")
        end
      end
    end
  end

  describe "named verifier" do
    context "verifiable object is not defined" do
      context "values are passed" do
        let(:values) {
          {
            foo: "foo",
            bar: "bar",
          }
        }

        before do
          target.verify :other, values
        end

        it "verifies the passed values" do
          expect(values).to eq(bar: "bar")
        end
      end

      context "values are not passed" do
        it "raises an error" do
          expect {
            target.verify :other
          }.to raise_error(RuntimeError) do |error|
            expect(error.message).to eq("Expected values to be passed")
          end
        end
      end
    end

    context "verifiable object is defined" do
      let(:params) {
        {
          baz: "baz",
          qux: "qux"
        }
      }

      before do
        local = self
        verifiable.class_eval do
          define_method :params do
            local.params
          end
        end

        verifiable.verifies :params
      end

      context "values are passed" do
        let(:values) {
          {
            foo: "foo",
            bar: "bar",
          }
        }

        before do
          target.verify :other, values
        end

        it "verifies the passed values" do
          expect(values).to eq(bar: "bar")
        end

        it "does not verify the verifiable object" do
          expect(params).to eq(baz: "baz", qux: "qux")
        end
      end

      context "values are not passed" do
        before do
          target.verify :other
        end

        it "verifies the verifiable object" do
          expect(params).to eq(qux: "qux")
        end
      end
    end
  end

  describe "verifying with no default or named verifiers" do
    let(:verifiable) {
      Class.new do
        include Pakyow::Behavior::Verification
      end
    }

    let(:values) {
      { foo: "foo" }
    }

    before do
      target.verify values
    end

    it "does not fail" do
      expect(values).to eq(foo: "foo")
    end
  end

  describe "delegating to the default verifier" do
    let(:verifiable) {
      Class.new do
        include Pakyow::Behavior::Verification

        required :foo
        optional :bar, default: "bar"
      end
    }

    let(:values) {
      { foo: "foo", baz: "baz" }
    }

    before do
      target.verify values
    end

    it "delegates successfully" do
      expect(values).to eq(foo: "foo", bar: "bar")
    end
  end

  describe "defining across many verify calls" do
    let(:verifiable) {
      Class.new do
        include Pakyow::Behavior::Verification

        verify do
          required :foo
        end

        verify do
          optional :bar, default: "bar"
        end
      end
    }

    let(:values) {
      { foo: "foo", baz: "baz" }
    }

    before do
      target.verify values
    end

    it "defines successfully" do
      expect(values).to eq(foo: "foo", bar: "bar")
    end
  end
end
