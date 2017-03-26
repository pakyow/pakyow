RSpec.describe "defining a router" do
  include_context "testable app"

  let :app_definition do
    -> {
      router do
        default
      end
    }
  end

  it "defines the router" do
    expect(call[0]).to eq(200)
  end

  context "when the router is defined with a path" do
    let :app_definition do
      -> {
        router "/foo" do
          default
        end
      }
    end

    it "defines the router" do
      expect(call("/foo")[0]).to eq(200)
    end
  end

  context "when the router is defined with a custom matcher" do
    let :app_definition do
      -> {
        klass = Class.new do
          def match?(path)
            true
          end
        end

        router klass.new do
          default
        end
      }
    end

    it "defines the router" do
      expect(call("/")[0]).to eq(200)
    end
  end

  context "when the router is a subclass" do
    class ChildRouter < Pakyow::Router
      default
    end

    let :autorun do
      false
    end

    before do
      Pakyow::App.router << ChildRouter
      run
    end

    it "defines the router" do
      expect(call[0]).to eq(200)
    end

    context "and we create the subclass with options" do
      class ChildRouterWithOptions < Pakyow::Router("/foo", before: [:bar])
        def bar; end
        default
      end

      before do
        Pakyow::App.router << ChildRouterWithOptions
        run
      end

      it "defines the router" do
        expect(call("/foo")[0]).to eq(200)
      end
    end
  end
end
