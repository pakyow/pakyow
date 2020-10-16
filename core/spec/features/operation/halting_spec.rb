RSpec.describe "halting an operation" do
  include_context "app"

  let :app_def do
    Proc.new do
      operation :test do
        attr_reader :foo_result, :bar_result

        action :foo do
          @foo_result = foo.reverse
          halt
        end

        action :bar do
          @bar_result = bar.reverse
        end
      end
    end
  end

  it "halts properly" do
    Pakyow.app(:test).operations.test(foo: "foo", bar: "bar").tap do |result|
      expect(result.foo_result).to eq("oof")
      expect(result.bar_result).to be(nil)
    end
  end
end
