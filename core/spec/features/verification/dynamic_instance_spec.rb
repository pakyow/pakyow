require "pakyow/behavior/verification"

RSpec.describe "dynamic instance-level verification" do
  let(:verifiable) {
    Class.new do
      include Pakyow::Behavior::Verification
    end
  }

  let(:target) {
    verifiable.new
  }

  context "verifiable object is not defined" do
    context "values are passed" do
      let(:values) {
        {
          foo: "foo",
          bar: "bar",
        }
      }

      before do
        target.verify values do
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
          target.verify do
            optional :foo
          end
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
        target.verify values do
          optional :foo
        end
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
        target.verify do
          optional :baz
        end
      end

      it "verifies the verifiable object" do
        expect(params).to eq(baz: "baz")
      end
    end
  end

  context "verification fails" do
    it "raises an invalid data error" do
      expect {
        target.verify bar: "baz" do
          required :foo
        end
      }.to raise_error(Pakyow::InvalidData)
    end

    describe "invalid data error" do
      let(:error) {
        begin
          target.verify bar: "baz" do
            required :foo
          end
        rescue => error
          error
        end
      }

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
        target.verify foo: "foo" do
          required :foo
        end
      }.not_to raise_error
    end
  end
end
