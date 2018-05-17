RSpec.describe "templates embedded by presenter" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)
    }
  end

  context "top-level scope" do
    it "embeds a template" do
      expect(call("/embeds/top-level")[2].body.read).to eq_sans_whitespace(
        <<~HTML
          <script type="text/template" data-version="default" data-b="post">
            <div data-b="post">
              <h1 data-b="title">title</h1>
            </div>
          </script>
        HTML
      )
    end
  end

  context "nested scope" do
    it "embeds a template" do
      expect(call("/embeds/nested")[2].body.read).to eq_sans_whitespace(
        <<~HTML
          <script type="text/template" data-version="default" data-b="post">
            <div data-b="post">
              <div data-b="comment">
                <h1 data-b="title">title</h1>
              </div>
            </div>
          </script>
        HTML
      )
    end
  end

  context "versioned bindings" do
    it "embeds a template" do
      expect(call("/embeds/versioned")[2].body.read).to eq_sans_whitespace(
        <<~HTML
          <script type="text/template" data-version="default" data-b="post">
            <div data-b="post">
              <h1 data-b="title">title1</h1>
            </div>
          </script>

          <script type="text/template" data-version="one" data-b="post">
            <div data-b="post">
              <h1 data-b="title">title2</h1>
            </div>
          </script>

          <script type="text/template" data-version="two" data-b="post">
            <div data-b="post">
              <h1 data-b="title">title3</h1>
            </div>
          </script>
        HTML
      )
    end
  end

  context "running in prototype mode" do
    let :mode do
      :prototype
    end

    it "does not create embedded templates" do
      expect(call("/embeds/top-level")[2].body.read).to eq_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <h1 data-b="title">title</h1>
          </div>
        HTML
      )
    end
  end
end
