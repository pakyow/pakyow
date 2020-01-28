RSpec.describe "accessing values through their instance variable" do
  include_context "app"

  let(:app_def) {
    Proc.new {
      operation :foo do
        attr_reader :instance_foo

        action do
          @instance_foo = @foo
        end
      end
    }
  }

  let(:values) {
    { foo: "foo" }
  }

  it "exposes the value" do
    expect(app.operations.foo(values).instance_foo).to eq("foo")
  end
end
