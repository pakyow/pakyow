RSpec.describe "templates embedded by presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  context "top-level scope" do
    let :view do
      Pakyow::Presenter::View.new("<div@post><h1@title>title</h1></div>")
    end

    it "embeds a template" do
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">title</h1></div><script type=\"text/template\" data-version=\"default\" data-s=\"post\"><div data-s=\"post\"><h1 data-p=\"title\">title</h1></div></script>")
    end
  end

  context "nested scope" do
    let :view do
      Pakyow::Presenter::View.new("<div@post><div@comment><h1@title>title</h1></div></div>")
    end

    it "embeds a template" do
      expect(presenter.to_s).to eq("<div data-s=\"post\"><div data-s=\"comment\"><h1 data-p=\"title\">title</h1></div><script type=\"text/template\" data-version=\"default\" data-s=\"comment\"><div data-s=\"comment\"><h1 data-p=\"title\">title</h1></div></script></div><script type=\"text/template\" data-version=\"default\" data-s=\"post\"><div data-s=\"post\"><div data-s=\"comment\"><h1 data-p=\"title\">title</h1></div></div></script>")
    end
  end

  context "versioned bindings" do
    let :view do
      Pakyow::Presenter::View.new("<div@post version=\"default\"><h1@title>title1</h1></div><div@post version=\"one\"><h1@title>title2</h1></div><div@post version=\"two\"><h1@title>title3</h1></div>")
    end

    it "embeds a template" do
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">title1</h1></div><script type=\"text/template\" data-version=\"default\" data-s=\"post\"><div data-s=\"post\"><h1 data-p=\"title\">title1</h1></div></script><script type=\"text/template\" data-version=\"one\" data-s=\"post\"><div data-s=\"post\"><h1 data-p=\"title\">title2</h1></div></script><script type=\"text/template\" data-version=\"two\" data-s=\"post\"><div data-s=\"post\"><h1 data-p=\"title\">title3</h1></div></script>")
    end
  end

  context "embedded template option is false" do
    let :presenter do
      Pakyow::Presenter::Presenter.new(view, embed_templates: false)
    end

    let :view do
      Pakyow::Presenter::View.new("<div@post><h1@title>title</h1></div>")
    end

    it "does not embed templates" do
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">title</h1></div>")
    end
  end
end
