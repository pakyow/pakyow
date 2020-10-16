RSpec.describe "installing the socket" do
  include_context "app"

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("12321")
  end

  it "installs the socket" do
    expect(call("/")[2]).to include_sans_whitespace(
      <<~HTML
        <meta name="pw-socket" data-ui="socket(global: true, endpoint: ws://localhost/pw-socket?id=MTIzMjE=~FGhnpS-4JBlFz4V-78zKBAIr0m7e-Mf1mryud9JZt0U=)">
      HTML
    )
  end

  context "secure request" do
    it "configures the socket to connect with wss" do
      expect(call("/", scheme: "https")[2]).to include_sans_whitespace(
        <<~HTML
          <meta name="pw-socket" data-ui="socket(global: true, endpoint: wss://localhost/pw-socket?id=MTIzMjE=~FGhnpS-4JBlFz4V-78zKBAIr0m7e-Mf1mryud9JZt0U=)">
        HTML
      )
    end
  end
end
