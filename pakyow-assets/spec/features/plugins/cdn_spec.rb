require "pakyow/plugin"

RSpec.describe "serving assets from a cdn for a plugin view" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      config.assets.host = "//s.pakyow.com"

      plug :testable
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
end
