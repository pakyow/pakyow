RSpec.describe "view transformation via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view, embed_templates: false)
  end

  let :view do
    Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1></div>")
  end

  let :part do
    presenter.find(:post, :title)
  end

  describe "with" do
    it "yields the presenter" do
      expect { |b| part.with(&b) }.to yield_with_args(part)
    end
  end

  describe "transform" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1><p binding=\"body\">body goes here</p></div>")
    end

    let :post_presenter do
      presenter.find(:post)
    end

    it "tranforms to match a single object, removing bindings for nonexistent values" do
      post_presenter.transform(body: "foo")
      expect(presenter.to_s).to eq("<div data-s=\"post\"><p data-p=\"body\">body goes here</p></div>")
    end

    it "tranforms to match an array of objects" do
      post_presenter.transform([{ title: "foo" }, { body: "bar" }])
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">title goes here</h1></div><div data-s=\"post\"><p data-p=\"body\">body goes here</p></div>")
    end

    context "value for binding is nil" do
      it "removes the binding" do
        post_presenter.transform(body: nil)
        expect(presenter.to_s).to eq("<div data-s=\"post\"></div>")
      end
    end
  end

  describe "append" do
    before do
      part.append(" hi")
    end

    it "appends" do
      expect(presenter.to_s).to include("<h1 data-p=\"title\">title goes here hi</h1>")
    end
  end

  describe "prepend" do
    before do
      part.prepend("hi ")
    end

    it "prepends" do
      expect(presenter.to_s).to include("<h1 data-p=\"title\">hi title goes here</h1>")
    end
  end

  describe "after" do
    before do
      part.after(" hi")
    end

    it "inserts after" do
      expect(presenter.to_s).to include("<h1 data-p=\"title\">title goes here</h1> hi")
    end
  end

  describe "before" do
    before do
      part.before("hi ")
    end

    it "inserts before" do
      expect(presenter.to_s).to include("hi <h1 data-p=\"title\">title goes here</h1>")
    end
  end

  describe "replace" do
    before do
      part.replace("hi")
    end

    it "replaces" do
      expect(presenter.to_s).to include("hi")
      expect(presenter.find(:post, :title)).to be nil
    end
  end

  describe "remove" do
    before do
      part.remove
    end

    it "removes" do
      expect(presenter.find(:post, :title)).to be nil
    end
  end

  describe "clear" do
    before do
      presenter.find(:post).clear
    end

    it "removes the children" do
      expect(presenter.find(:post)).not_to be nil
      expect(presenter.find(:post, :title)).to be nil
    end
  end
end
