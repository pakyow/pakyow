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

  context "when router is a subclass" do
    class ChildRouter < Pakyow::Router
      default
    end

    before do
      Pakyow::App.router << ChildRouter
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
      end

      it "defines the router" do
        expect(call("/foo")[0]).to eq(200)
      end
    end
  end
end
