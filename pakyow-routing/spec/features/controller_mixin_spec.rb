RSpec.describe "including mixins into a controller" do
  include_context "app"

  module RouteMixins
    def foo
      send "mixin"
    end
  end

  let :app_init do
    Proc.new {
      controller do
        include RouteMixins

        default do
          foo
        end
      end
    }
  end

  it "makes the methods available" do
    expect(call[2]).to eq("mixin")
  end
end
