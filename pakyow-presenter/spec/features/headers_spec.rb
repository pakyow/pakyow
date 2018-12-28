RSpec.describe "response headers for presented requests" do
  include_context "app"

  let :app_definition do
    Proc.new do
      instance_exec(&$presenter_app_boilerplate)
    end
  end

  it "sets Content-Length" do
    expect(call("/")[1]["Content-Length"]).to eq(108)
  end

  it "sets Content-Type" do
    expect(call("/")[1]["Content-Type"]).to eq("text/html")
  end
end
