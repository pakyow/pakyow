require "pakyow/framework"

RSpec.describe "building an application" do
  context "after make hooks are defined by a framework" do
    before do
      Class.new(Pakyow::Framework(:test)) do
        def boot
          object.after "make" do
            define_method(:foo) {}
          end
        end
      end
    end

    it "calls the after make hooks" do
      expect(Pakyow.app(:test).instance_methods(false)).to include(:foo)
    end
  end
end
