require "pakyow/support/inspectable"

RSpec.describe Pakyow::Support::Inspectable do
  let :inspectable do
    Class.new do
      include Pakyow::Support::Inspectable
      inspectable :@ivar_one, :method_two

      def initialize
        @ivar_one = :one
        @ivar_two = :two
      end

      def method_two
        :mtwo
      end
    end
  end

  let :instance do
    inspectable.new
  end

  it "inspects ivar_one" do
    expect(instance.inspect).to include("@ivar_one=:one")
  end

  it "inspects method_two" do
    expect(instance.inspect).to include("method_two=:mtwo")
  end

  it "includes the object id" do
    expect(instance.inspect).to include(instance.object_id.to_s)
  end

  it "includes the class" do
    expect(instance.inspect).to include(instance.class.to_s)
  end

  it "does not inspect ivar_two" do
    expect(instance.inspect).to_not include("@ivar_two=:two")
  end

  context "nothing is set as inspectable" do
    let(:inspectable) {
      Class.new {
        include Pakyow::Support::Inspectable

        def initialize
          @ivar_one = :one
        end
      }
    }

    it "does a normal inspection" do
      expect(instance.inspect).to include("@ivar_one=:one")
    end
  end

  context "inspecting a private method" do
    let :inspectable do
      Class.new do
        include Pakyow::Support::Inspectable
        inspectable :private_method

        private def private_method
          :private
        end
      end
    end

    it "inspects" do
      expect(instance.inspect).to include("private_method=:private")
    end
  end

  describe "inspect recursion" do
    let :inspectable do
      Class.new do
        include Pakyow::Support::Inspectable
        inspectable :@foo

        def initialize
          @foo = self
        end
      end
    end

    it "protects against recursion" do
      expect(instance.inspect).to include("...")
    end
  end
end
