RSpec.describe "detecting requests originating from the ui" do
  include_context "app"

  let :app_def do
    Proc.new do
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
    expect(call("/ui-test", headers: { "pw-ui" => "version" })[2]).to eq("true")
  end

  it "detects non-ui requests" do
    expect(call("/ui-test")[2]).to eq("false")
  end

  it "exposes the client version" do
    expect(call("/ui-version", headers: { "pw-ui" => "version" })[2]).to eq("version")
  end
end
