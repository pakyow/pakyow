RSpec.describe "extending a controller with an extension" do
  include_context "app"

  module RouteExtensions
    extend Pakyow::Support::Extension

    apply_extension do
      default do
        send "extension"
      end
    end
  end

  let :app_def do
    Proc.new {
      controller :haha do
        include RouteExtensions
      end
    }
  end

  it "makes the extensions available to the controller" do
    expect(call[0]).to eq(200)
    expect(call[2]).to eq("extension")
  end
end
