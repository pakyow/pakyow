require "pakyow/support/configurable"

RSpec.describe "evaling the value of a setting in a context" do
  let :object do
    Class.new do
      include Pakyow::Support::Configurable

      def name
        :configurable
      end
    end
  end

  context "setting value is a block" do
    before do
      object.setting :foo, "foo"

      object.configure do
        config.foo do
          self.class
        end
      end

      object.configure!

      @instance = object.new
    end

    it "evals the value in the expected context" do
      expect(@instance.config.eval(:foo, self)).to be(self.class)
    end
  end

  context "setting value is not a block" do
    before do
      object.setting :foo, "foo"

      object.configure do
        config.foo = :foo
      end

      object.configure!

      @instance = object.new
    end

    it "returns the value" do
      expect(@instance.config.eval(:foo, self)).to be(:foo)
    end
  end
end
