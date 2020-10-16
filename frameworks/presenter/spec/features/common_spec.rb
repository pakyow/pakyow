RSpec.describe "loading the common frontend into applications" do
  before do
    Pakyow.config.root = File.expand_path("../common/support/project", __FILE__)
  end

  include_context "app"

  let(:app_def) {
    Proc.new {
      configure do
        config.presenter.embed_authenticity_token = false
      end
    }
  }

  it "exposes common view paths" do
    expect(call("/common")[2]).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>common layout</title>
          </head>

          <body>
            common page

            common include

            common partial
          </body>
        </html>
      HTML
    )
  end

  it "exposes application view paths" do
    expect(call("/")[2]).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>app layout</title>
          </head>

          <body>
            app page

            app include
          </body>
        </html>
      HTML
    )
  end

  it "exposes common layouts" do
    expect(call("/with-common-layout")[2]).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>common layout</title>
          </head>

          <body>
            page with common layout
          </body>
        </html>
      HTML
    )
  end

  it "exposes common includes" do
    expect(call("/with-common-include")[2]).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>app layout</title>
          </head>

          <body>
            common include
          </body>
        </html>
      HTML
    )
  end

  # Partials stick within the pages they are defined. Sharing across frontend paths should use includes.
  #
  it "does not expose common partials" do
    expect(call("/with-common-partial")[2]).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>app layout</title>
          </head>

          <body>
            <!-- @include common-partial -->
          </body>
        </html>
      HTML
    )
  end

  context "application defines an identical view path" do
    it "gives precedence to application views" do
      expect(call("/app-override")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>app layout</title>
            </head>

            <body>
              app
            </body>
          </html>
        HTML
      )
    end
  end

  describe "overriding a layout in the application" do
    it "builds the common view with the application's layout" do
      expect(call("/app-layout-override")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>app override layout</title>
            </head>

            <body>
              common page
            </body>
          </html>
        HTML
      )
    end
  end

  describe "overriding an include in the application" do
    it "builds the common view with the application's include" do
      expect(call("/app-include-override")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>common layout</title>
            </head>

            <body>
              app include override
            </body>
          </html>
        HTML
      )
    end
  end

  describe "overriding a partial in the application" do
    # Partials stick within the pages they are defined. Sharing across frontend paths should use includes.
    #
    it "builds the common view with the common partial" do
      expect(call("/app-partial-override")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>common layout</title>
            </head>

            <body>
              common override partial
            </body>
          </html>
        HTML
      )
    end
  end
end
