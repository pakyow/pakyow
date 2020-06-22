RSpec.describe "passing arguments through an operation" do
  include_context "app"

  let(:app_def) {
    local = self

    Proc.new {
      operation :foo do
        action do |arg_1, arg_2, foo:|
          local.arguments = {
            arg_1: arg_1,
            arg_2: arg_2,
            foo: foo
          }
        end
      end
    }
  }

  attr_accessor :arguments

  let(:operation) {
    app.operations(:foo).new
  }

  it "passes arguments through the operation" do
    operation.perform(:foo, :bar, foo: :baz)

    expect(arguments).to eq({
      arg_1: :foo,
      arg_2: :bar,
      foo: :baz
    })
  end
end
