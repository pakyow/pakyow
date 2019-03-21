RSpec.describe "view transformation via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
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
      expect(presenter.view.to_s).to eq("<div data-b=\"post\"><p data-b=\"body\">body goes here</p></div>")
    end

    it "tranforms to match an array of objects" do
      post_presenter.transform([{ title: "foo" }, { body: "bar" }])
      expect(presenter.view.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">title goes here</h1></div><div data-b=\"post\"><p data-b=\"body\">body goes here</p></div>")
    end

    context "value for binding is nil" do
      it "removes the binding" do
        post_presenter.transform(body: nil)
        expect(presenter.view.to_s).to eq("<div data-b=\"post\"></div>")
      end
    end

    context "object is empty" do
      it "removes the binding" do
        post_presenter.transform([])
        expect(presenter.view.to_s).to eq("")
      end
    end

    context "object is nil" do
      it "removes the binding" do
        post_presenter.transform(nil)
        expect(presenter.view.to_s).to eq("")
      end
    end

    context "object does not respond to empty" do
      let :object do
        Struct.new(:title, :body) do
          def value?(key)
            !!self[key]
          end
        end
      end

      it "attempts to bind" do
        post_presenter.transform(object.new("title"))
        expect(presenter.view.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">title goes here</h1></div>")
      end
    end

    context "scope/prop is defined on a single node" do
      let :view do
        Pakyow::Presenter::View.new("<h1 binding=\"post.title\">title goes here</h1>")
      end

      it "transforms" do
        post_presenter.transform(title: "foo")
        expect(presenter.view.to_s).to eq("<h1 data-b=\"post.title\">title goes here</h1>")
      end
    end
  end

  describe "append" do
    before do
      part.append(" hi")
    end

    it "appends" do
      expect(presenter.view.to_s).to include("<h1 data-b=\"title\">title goes here hi</h1>")
    end
  end

  describe "prepend" do
    before do
      part.prepend("hi ")
    end

    it "prepends" do
      expect(presenter.view.to_s).to include("<h1 data-b=\"title\">hi title goes here</h1>")
    end
  end

  describe "after" do
    before do
      part.after(" hi")
    end

    it "inserts after" do
      expect(presenter.view.to_s).to include("<h1 data-b=\"title\">title goes here</h1> hi")
    end
  end

  describe "before" do
    before do
      part.before("hi ")
    end

    it "inserts before" do
      expect(presenter.view.to_s).to include("hi <h1 data-b=\"title\">title goes here</h1>")
    end
  end

  describe "replace" do
    before do
      part.replace("hi")
    end

    it "replaces" do
      expect(presenter.view.to_s).to include("hi")
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

  describe "html=" do
    before do
      presenter.find(:post).html = "foo"
    end

    it "replaces the html" do
      expect(presenter.find(:post).to_s).to eq('<div data-b="post">foo</div>')
    end

    context "passed a nil value" do
      before do
        presenter.find(:post).html = nil
      end

      it "replaces the html" do
        expect(presenter.find(:post).to_s).to eq('<div data-b="post"></div>')
      end
    end
  end
end
