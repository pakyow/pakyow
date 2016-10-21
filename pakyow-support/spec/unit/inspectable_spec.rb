require "pakyow/support/inspectable"

RSpec.describe Pakyow::Support::Inspectable do
  let :ivars do
    [:ivar_one]
  end

  let :inspectable do
    Class.new {
      include Pakyow::Support::Inspectable
      inspectable :ivar_one

      def initialize
        @ivar_one = :one
        @ivar_two = :two
      end
    }
  end

  context "when inspecting an instance" do
    it "inspects ivar_one" do
      expect(inspectable.new.inspect).to include("@ivar_one")
    end

    it "does not inspect ivar_two" do
      expect(inspectable.new.inspect).to_not include("@ivar_two")
    end
  end
end
