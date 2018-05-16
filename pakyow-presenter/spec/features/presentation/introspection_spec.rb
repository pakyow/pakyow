RSpec.describe "view introspection via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  describe "text" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><span>foo</span></div>")
    end

    it "returns the text value" do
      expect(presenter.find(:post).text).to eq("foo")
    end
  end

  describe "html" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><span>foo</span></div>")
    end

    it "returns the html value" do
      expect(presenter.find(:post).html).to eq("<span>foo</span>")
    end
  end

  describe "version" do
    context "view is versioned" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" version=\"foo\"></div>")
      end

      it "returns the version" do
        expect(presenter.find(:post).version).to eq(:foo)
      end
    end

    context "view is not versioned" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
      end

      it "returns default" do
        expect(presenter.find(:post).version).to eq(:default)
      end
    end
  end

  describe "binding?" do
    context "view has a binding" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
      end

      it "returns true" do
        expect(presenter.find(:post).binding?).to be true
      end
    end
  end

  describe "form?" do
    context "view is a form" do
      let :view do
        Pakyow::Presenter::View.new("<form binding=\"post\"></form>")
      end

      it "returns true" do
        expect(presenter.form(:post).form?).to be true
      end
    end

    context "view is not a form" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
      end

      it "returns false" do
        expect(presenter.find(:post).form?).to be false
      end
    end
  end

  describe "title" do
    context "title node exists" do
      let :view do
        Pakyow::Presenter::View.new("<head><title>foo</title></head>")
      end

      it "gets the value" do
        expect(presenter.title).to eq("foo")
      end
    end

    context "title node does not exist" do
      let :view do
        Pakyow::Presenter::View.new("<head></head>")
      end

      it "returns nil" do
        expect(presenter.title).to eq(nil)
      end
    end
  end

  describe "==" do
    let :view do
      Pakyow::Presenter::View.new("<div></div>")
    end

    it "returns true when presenters are presenting equal views" do
      comparison = Pakyow::Presenter::Presenter.new(Pakyow::Presenter::View.new("<div></div>"))
      expect(presenter == comparison).to be true
    end

    it "returns false when presenters are presenting views that are not equal" do
      comparison = Pakyow::Presenter::Presenter.new(Pakyow::Presenter::View.new("<div>foo</div>"))
      expect(presenter == comparison).to be false
    end
  end
end
