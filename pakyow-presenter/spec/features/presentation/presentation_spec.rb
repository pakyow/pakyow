RSpec.describe "presenting data via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view, embed_templates: false)
  end

  let :view do
    Pakyow::Presenter::View.new("<div@post><h1@title>title goes here</h1><p@body>body goes here</p></div>")
  end

  let :post_presenter do
    presenter.find(:post)
  end

  it "presents a single object" do
    post_presenter.present(body: "foo")
    expect(presenter.to_s).to eq("<div data-s=\"post\"><p data-p=\"body\">foo</p></div>")
  end

  it "presents an array of objects" do
    post_presenter.present([{ title: "foo" }, { body: "bar" }])
    expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">foo</h1></div><div data-s=\"post\"><p data-p=\"body\">bar</p></div>")
  end

  context "presenting a deeply nested data structure" do
    let :view do
      Pakyow::Presenter::View.new("<div@post><h1@title>title goes here</h1><p@body>body goes here</p><div@comment><p@body>comment body goes here</p></div>")
    end

    it "presents recursively" do
      post_presenter.present([{ title: "foo" }, { body: "bar", comment: [{ body: "comment1" }, { body: "comment2" }] }])
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">foo</h1></div><div data-s=\"post\"><p data-p=\"body\">bar</p><div data-s=\"comment\"><p data-p=\"body\">comment1</p></div><div data-s=\"comment\"><p data-p=\"body\">comment2</p></div></div>")
    end
  end
end
