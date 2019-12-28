RSpec.describe "namespaced routes" do
  include_context "app"

  let :app_init do
    Proc.new {
      controller do
        namespace :ns, "/ns" do
          action :foo
          action :bar

          def foo
            $calls << :foo
          end

          def bar
            $calls << :bar
          end

          default do
            $calls << :route
          end
        end
      end
    }
  end

  before do
    $calls = []
  end

  it "is called" do
    expect(call("/ns")[0]).to eq(200)
  end

  it "calls the actions and route in order" do
    call("/ns")

    expect($calls[0]).to eq(:foo)
    expect($calls[1]).to eq(:bar)
    expect($calls[2]).to eq(:route)
  end

  context "when a route is defined in a parameterized namespace" do
    let :app_init do
      Proc.new {
        controller do
          namespace :ns, "/ns/:id" do
            default do
              send params[:id] || ""
            end
          end
        end
      }
    end

    it "is called" do
      expect(call("/ns/123")[0]).to eq(200)
    end

    it "makes the parameters available to the route" do
      expect(call("/ns/123")[2]).to eq("123")
    end
  end

  context "when a namespace is defined without a name" do
    let :app_init do
      Proc.new {
        controller do
          namespace "/ns" do
            default do
              send "ns"
            end
          end
        end
      }
    end

    it "is called" do
      expect(call("/ns")[0]).to eq(200)
    end
  end

  context "when a namespace is defined within a controller with a name and path" do
    let :app_init do
      Proc.new {
        controller :top, "/top" do
          namespace :ns, "/ns" do
            default do
              send "ns"
            end
          end
        end
      }
    end

    it "is called" do
      expect(call("/top/ns")[0]).to eq(200)
    end
  end

  describe "defining routes for the same namespace multiple times" do
    let :app_init do
      Proc.new {
        controller do
          namespace :n, "/n" do
            get :foo, "/foo"
          end

          namespace :n do
            get :bar, "/bar"
          end
        end
      }
    end

    let :controllers do
      Pakyow.apps.first.controllers.definitions
    end

    it "adds routes to the existing group" do
      expect(controllers.count).to eq(1)
      expect(controllers[0].children.count).to eq(1)
      expect(controllers[0].children[0].routes.values.flatten.count).to eq(2)
      expect(controllers[0].children[0].routes.values.flatten.map(&:name)).to eq([:foo, :bar])
    end
  end
end
