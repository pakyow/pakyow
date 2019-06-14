require "pakyow/behavior/verification"

RSpec.describe Pakyow::Behavior::Verification do
  include Pakyow::Behavior::Verification

  before do
    self.class.instance_variable_set(:@__object_name_to_verify, nil)
  end

  context "object to verify is not defined" do
    context "values are passed" do
      let :values do
        {
          foo: "foo",
          bar: "bar",
        }
      end

      before do
        verify values do
          optional :foo
        end
      end

      it "verifies the passed values" do
        expect(values).to eq(foo: "foo")
      end
    end

    context "values are not passed" do
      it "raises an error" do
        expect {
          verify do
            optional :foo
          end
        }.to raise_error(RuntimeError) do |error|
          expect(error.message).to eq("Expected values to be passed")
        end
      end
    end
  end

  context "object to verify is defined" do
    let :params do
      {
        baz: "baz",
        qux: "qux"
      }
    end

    before do
      self.class.verifies :params
    end

    context "values are passed" do
      let :values do
        {
          foo: "foo",
          bar: "bar",
        }
      end

      before do
        verify values do
          optional :foo
        end
      end

      it "verifies the passed values" do
        expect(values).to eq(foo: "foo")
      end

      it "does not verify the object to verify" do
        expect(params).to eq(baz: "baz", qux: "qux")
      end
    end

    context "values are not passed" do
      before do
        verify do
          optional :baz
        end
      end

      it "verifies the object to verify" do
        expect(params).to eq(baz: "baz")
      end
    end
  end

  context "verification fails" do
    it "raises an invalid data error" do
      expect {
        verify bar: "baz" do
          required :foo
        end
      }.to raise_error(Pakyow::InvalidData)
    end

    describe "invalid data error" do
      let :error do
        verify bar: "baz" do
          required :foo
        end
      rescue => error
        error
      end

      it "has the correct message" do
        expect(error.message).to eq("Provided data didn't pass verification")
      end

      it "has the correct context" do
        expect(error.context[:object]).to eq(bar: "baz")
        expect(error.context[:result]).to be_instance_of(Pakyow::Verifier::Result)
      end
    end
  end

  context "verification succeeds" do
    it "does not raise an error" do
      expect {
        verify foo: "foo" do
          required :foo
        end
      }.not_to raise_error
    end
  end
end
