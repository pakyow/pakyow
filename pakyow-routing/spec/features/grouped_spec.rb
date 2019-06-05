RSpec.describe "grouped routes" do
  include_context "app"

  let :app_init do
    Proc.new {
      controller do
        action :foo

        def foo
        end

        group :g do
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
    expect(call[0]).to eq(200)
  end

  it "calls the actions and route in order" do
    call

    expect($calls[0]).to eq(:foo)
    expect($calls[1]).to eq(:bar)
    expect($calls[2]).to eq(:route)
  end

  describe "defining routes for the same group multiple times" do
    let :app_init do
      Proc.new {
        controller do
          group :g do
            get :foo, "/foo"
          end

          group :g do
            get :bar, "/bar"
          end
        end
      }
    end

    let :controllers do
      Pakyow.apps.first.state(:controller)
    end

    it "adds routes to the existing group" do
      expect(controllers.count).to eq(1)
      expect(controllers[0].children.count).to eq(1)
      expect(controllers[0].children[0].routes.values.flatten.count).to eq(2)
      expect(controllers[0].children[0].routes.values.flatten.map(&:name)).to eq([:foo, :bar])
    end
  end
end
