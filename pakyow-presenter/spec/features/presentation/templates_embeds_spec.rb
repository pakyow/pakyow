RSpec.describe "templates embedded by presenter" do
  include_context "app"

  context "top-level scope" do
    it "embeds a template" do
      expect(call("/embeds/top-level")[2].body.read).to eq_sans_whitespace(
        <<~HTML
          <script type="text/template" data-b="post">
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
          <script type="text/template" data-b="post">
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
          <script type="text/template" data-b="post" data-v="default">
            <div data-b="post" data-v="default">
              <h1 data-b="title">title1</h1>
            </div>
          </script>

          <script type="text/template" data-b="post" data-v="one">
            <div data-b="post" data-v="one">
              <h1 data-b="title">title2</h1>
            </div>
          </script>

          <script type="text/template" data-b="post" data-v="two">
            <div data-b="post" data-v="two">
              <h1 data-b="title">title3</h1>
            </div>
          </script>
        HTML
      )
    end
  end

  context "form" do
    it "does not embed a template" do
      expect(call("/embeds/form")[2].body.read).not_to include("script")
    end
  end

  context "scope within form" do
    it "embeds a template" do
      expect(call("/embeds/scope-within-form")[2].body.read).to include_sans_whitespace(
        <<~HTML
          <script type="text/template" data-b="tag" data-c="form">
            <li data-b="tag" data-c="form">
              <input type="text" data-b="name" data-c="form">
            </li>
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
