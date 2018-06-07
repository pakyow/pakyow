RSpec.describe "errors during implicit presentation" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      controller do
        default do
        end
      end

      presenter "/" do
        fail "failed in presenter"
      end
    }
  end

  let :mode do
    :development
  end

  it "handles the error" do
    expect(call("/")[0]).to eq(500)
    expect(call("/")[2].body.read).to include("RuntimeError")
    expect(call("/")[2].body.read).to include("failed in presenter")
  end
end
