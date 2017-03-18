RSpec.describe "extending a router" do
  include_context "testable app"

  module RouteExtensions
    extend Pakyow::Routing::Extension

    default do
      send "extension"
    end
  end

  def define
    Pakyow::App.define do
      router do
        include RouteExtensions
      end
    end
  end

  it "makes the extensions available to the router" do
    expect(call[2].body.read).to eq("extension")
  end
end
