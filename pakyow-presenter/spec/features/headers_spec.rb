RSpec.describe "response headers for presented requests" do
  include_context "app"

  it "sets content-type" do
    expect(call("/")[1]["content-type"]).to eq("text/html")
  end
end
