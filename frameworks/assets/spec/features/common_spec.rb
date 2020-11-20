RSpec.describe "using common assets" do
  before do
    Pakyow.config.root = File.expand_path("../common/support/project", __FILE__)
  end

  include_context "app"

  let :app_def do
    Proc.new do
      configure do
        config.root = File.expand_path("../common/support/project/apps/test", __FILE__)
        config.assets.source_maps = false
        config.presenter.embed_authenticity_token = false
      end
    end
  end

  it "exposes common assets" do
    expect(call("/assets/common.css")[2]).to eq_sans_whitespace(
      <<~CSS
        body {
          background: #0d0d0d;
        }
      CSS
    )
  end

  it "exposes common packs" do
    expect(call("/assets/packs/common.js")[2]).to eq_sans_whitespace(
      <<~JS
        "use strict";

        console.log("hello");
      JS
    )
  end

  it "includes common packs in views" do
    expect(call("/")[2]).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>default</title>

            <script async src="/assets/packs/common.js"></script>
          </head>
          <body>
            index
          </body>
        </html>
      HTML
    )
  end
end
