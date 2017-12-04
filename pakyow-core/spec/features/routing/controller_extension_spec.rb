RSpec.describe "extending a controller" do
  include_context "testable app"

  module RouteExtensions
    extend Pakyow::Routing::Extension

    default do
      send "extension"
    end
  end

  let :app_definition do
    Proc.new {
      controller do
        include RouteExtensions
      end
    }
  end

  it "makes the extensions available to the controller" do
    expect(call[2].body.read).to eq("extension")
  end
end
