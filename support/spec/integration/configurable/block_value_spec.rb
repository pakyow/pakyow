require "pakyow/support/configurable"

RSpec.describe "setting a block as a value" do
  let :object do
    Class.new do
      include Pakyow::Support::Configurable

      def name
        :configurable
      end
    end
  end

  before do
    object.setting :foo, "foo"

    object.configure do
      config.foo do |input|
        input.reverse
      end
    end

    object.configure!

    @instance = object.new
  end

  it "sets the value" do
    expect(@instance.config.foo.call("foo")).to eq("oof")
  end
end
