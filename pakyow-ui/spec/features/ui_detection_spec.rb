RSpec.describe "detecting requests originating from the ui" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      controller do
        get "/ui-test" do
          send ui?.to_s
        end

        get "/ui-version" do
          send ui.to_s
        end
      end
    end
  end

  it "detects ui requests" do
    expect(call("/ui-test", "HTTP_PW_UI" => "version")[2].body.read).to eq("true")
  end

  it "detects non-ui requests" do
    expect(call("/ui-test")[2].body.read).to eq("false")
  end

  it "exposes the client version" do
    expect(call("/ui-version", "HTTP_PW_UI" => "version")[2].body.read).to eq("version")
  end
end
