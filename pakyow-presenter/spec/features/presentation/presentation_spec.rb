RSpec.describe "presenting data via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view, embed_templates: false)
  end

  let :view do
    Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1><p binding=\"body\">body goes here</p></div>")
  end

  let :post_presenter do
    presenter.find(:post)
  end

  it "presents a single object" do
    post_presenter.present(body: "foo")
    expect(presenter.to_s).to eq("<div data-b=\"post\"><p data-b=\"body\">foo</p></div>")
  end

  it "presents an array of objects" do
    post_presenter.present([{ title: "foo" }, { body: "bar" }])
    expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1></div><div data-b=\"post\"><p data-b=\"body\">bar</p></div>")
  end

  context "presenting a deeply nested data structure" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1><p binding=\"body\">body goes here</p><div binding=\"comment\"><p binding=\"body\">comment body goes here</p></div>")
    end

    it "presents recursively" do
      post_presenter.present([{ title: "foo" }, { body: "bar", comment: [{ body: "comment1" }, { body: "comment2" }] }])
      expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1></div><div data-b=\"post\"><p data-b=\"body\">bar</p><div data-b=\"comment\"><p data-b=\"body\">comment1</p></div><div data-b=\"comment\"><p data-b=\"body\">comment2</p></div></div>")
    end
  end
end
