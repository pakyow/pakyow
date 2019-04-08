RSpec.describe "reading attributes via presenter" do
  include_context "app"

  let :presenter do
    Pakyow::Presenter::Presenter.new(view, app: Pakyow.apps[0])
  end

  let :view do
    Pakyow::Presenter::View.new("<div binding=\"post\" title=\"foo\"></div>").find(:post)
  end

  it "responds the same to attrs or attributes" do
    expect(presenter.attrs).to be(presenter.attributes)
  end

  context "string attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" title=\"foo\"></div>").find(:post)
      end

      it "can be read" do
        expect(presenter.attributes[:title]).to eq("foo")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "is empty" do
        expect(presenter.attributes[:title]).to be_empty
      end
    end
  end

  context "hash attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" style=\"color:red\"></div>").find(:post)
      end

      it "can be read" do
        expect(presenter.attributes[:style]).to eq(color: "red")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "is empty" do
        expect(presenter.attributes[:title]).to be_empty
      end
    end
  end

  context "set attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" class=\"foo bar\"></div>").find(:post)
      end

      it "can be read" do
        expect(presenter.attributes[:class]).to eq(Set.new([:foo, :bar]))
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "is empty" do
        expect(presenter.attributes[:class]).to be_empty
      end
    end
  end

  context "boolean attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" checked=\"checked\"></div>").find(:post)
      end

      it "can be read" do
        expect(presenter.attributes[:checked]).to eq(true)
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "is false" do
        expect(presenter.attributes[:checked]).to eq(false)
      end
    end
  end
end
