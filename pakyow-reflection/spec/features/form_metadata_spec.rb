RSpec.describe "form metadata" do
  include_context "reflectable app"

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("key")
  end

  let :frontend_test_case do
    "metadata"
  end

  let :metadata do
    response = call("/")
    expect(response[0]).to eq(200)

    response_body = response[2].body.read
    expect(response_body).to include("input type=\"hidden\" name=\"_form\"")

    JSON.parse(
      Pakyow::Support::MessageVerifier.new("key").verify(
        response_body.match(/name=\"_form\" value=\"([^\"]+)\"/)[1]
      )
    )
  end

  it "embeds view path" do
    expect(metadata["view_path"]).to eq("/")
  end
end
