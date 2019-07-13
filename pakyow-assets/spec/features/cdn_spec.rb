RSpec.describe "configuring assets to serve content from a cdn" do
  include_context "app"

  let :app_def do
    Proc.new do
      config.assets.prefix = "//s.pakyow.com"
    end
  end

  it "builds the paths correctly" do
    expect(call("/")[2]).to include_sans_whitespace(
      <<~HTML
        <script type="text/javascript" src="//s.pakyow.com/default.js"></script>
      HTML
    )
  end
end
