RSpec.describe "extending a router" do
  include_context "testable app"

  module RouteExtensions
    extend Pakyow::Routing::Extension

    default do
      send "extension"
    end
  end

  let :app_definition do
    Proc.new {
      router do
        include RouteExtensions
      end
    }
  end

  it "makes the extensions available to the router" do
    expect(call[2].body.read).to eq("extension")
  end
end
