RSpec.describe "using an operation's getters and setters" do
  include_context "app"

  let(:app_def) {
    Proc.new {
      operation :foo do
        action do
          self.foo = foo.reverse
        end
      end
    }
  }

  let(:values) {
    { foo: "foo" }
  }

  it "defines a dynamic getter and setter for each value" do
    expect(app.operations.foo(values).foo).to eq("oof")
  end
end
