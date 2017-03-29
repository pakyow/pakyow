RSpec.describe "including mixins into a router" do
  include_context "testable app"

  module RouteMixins
    def foo
      send "mixin"
    end
  end

  let :app_definition do
    -> {
      router do
        include RouteMixins

        default do
          foo
        end
      end
    }
  end

  it "makes the methods available" do
    expect(call[2].body.read).to eq("mixin")
  end
end
