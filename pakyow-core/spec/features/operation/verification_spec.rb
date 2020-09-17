RSpec.describe "verifying operation values" do
  include_context "app"

  let :app_def do
    Proc.new do
      operation :test do
        verify do
          required :foo
          optional :bar
        end
      end
    end
  end

  context "verification fails" do
    it "raises an error" do
      expect {
        Pakyow.app(:test).operations.test
      }.to raise_error(Pakyow::InvalidData)
    end
  end

  context "verification succeeds" do
    it "calls the pipeline with sanitized values" do
      Pakyow.app(:test).operations.test(foo: "foo", bar: "bar", baz: "baz").tap do |operation|
        Pakyow::Support::Deprecator.global.ignore do
          expect(operation.values).to eq(foo: "foo", bar: "bar")
        end
      end
    end
  end
end
