RSpec.describe "configuring assets to serve content from a cdn" do
  include_context "app"

  let :app_def do
    Proc.new do
      config.assets.host = "//s.pakyow.com"
    end
  end

  it "builds asset path correctly" do
    expect(call("/cdn")[2]).to include_sans_whitespace(
      <<~HTML
        <script type="text/javascript" src="//s.pakyow.com/assets/default.js"></script>
      HTML
    )
  end

  it "builds pack paths correctly" do
    expect(call("/cdn")[2]).to include_sans_whitespace(
      <<~HTML
        <script src="//s.pakyow.com/assets/packs/test.js"></script>
        <link rel="stylesheet" type="text/css" media="all" href="//s.pakyow.com/assets/packs/test.css">
      HTML
    )
  end

  it "replaces asset references correctly" do
    expect(call("/assets/reference.css")[2]).to include_sans_whitespace(
      <<~HTML
        url("//s.pakyow.com/assets/images/test.png")
      HTML
    )
  end

  it "correctly handles clashing assets" do
    content = call("/assets/reference.css")[2]

    expect(content).to include_sans_whitespace(
      <<~HTML
        src: url("//s.pakyow.com/assets/fonts/test.woff") format("woff"),
             url("//s.pakyow.com/assets/fonts/test.woff2") format("woff2");
      HTML
    )
  end
end
