RSpec.describe "form metadata" do
  include_context "app"

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("key")
  end

  let :metadata do
    response = call("/")
    expect(response[0]).to eq(200)

    response_body = response[2]
    expect(response_body).to include("input type=\"hidden\" name=\"_form\"")

    JSON.parse(
      Pakyow::Support::MessageVerifier.new("key").verify(
        response_body.match(/name=\"_form\" value=\"([^\"]+)\"/)[1]
      )
    )
  end

  it "embeds channeled binding" do
    expect(metadata["binding"]).to eq("post:form")
  end

  it "embeds the form origin" do
    expect(metadata["origin"]).to eq("/")
  end
end
