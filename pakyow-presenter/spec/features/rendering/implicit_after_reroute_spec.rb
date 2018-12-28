RSpec.describe "rendering implicitly after a reroute" do
  include_context "app"

  let :app_init do
    Proc.new do
      controller :default do
        default do
          reroute "/other"
        end
      end
    end
  end

  it "renders the correct view" do
    response = call("/")
    expect(response[0]).to eq(200)
    expect(response[2].body.read).to eq("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    other\n\n  </body>\n</html>\n")
  end
end
