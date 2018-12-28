RSpec.describe "defining a controller" do
  include_context "app"

  let :app_definition do
    Proc.new {
      controller do
        default
      end
    }
  end

  it "defines the controller" do
    expect(call[0]).to eq(200)
  end

  context "when the controller is defined with a path" do
    let :app_definition do
      Proc.new {
        controller "/foo" do
          default
        end
      }
    end

    it "defines the controller" do
      expect(call("/foo")[0]).to eq(200)
    end
  end

  context "when the controller is defined with a custom matcher" do
    let :app_definition do
      Proc.new {
        klass = Class.new do
          def match(path)
            self
          end

          def named_captures
            {}
          end
        end

        controller klass.new do
          default
        end
      }
    end

    it "defines the controller" do
      expect(call("/")[0]).to eq(200)
    end
  end

  xcontext "when the controller is a subclass" do
    class ChildController < Pakyow::Controller
      default
    end

    let :autorun do
      false
    end

    before do
      Pakyow::App.controller << ChildController
      run
    end

    it "defines the controller" do
      expect(call[0]).to eq(200)
    end
  end

  xcontext "when the controller is a subclass and we create the subclass with options" do
    class ChildControllerWithOptions < Pakyow::Controller("/foo")
      default
    end

    before do
      Pakyow::App.controller << ChildControllerWithOptions
      run
    end

    it "defines the controller" do
      expect(call("/foo")[0]).to eq(200)
    end
  end
end
