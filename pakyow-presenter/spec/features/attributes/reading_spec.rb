RSpec.describe "reading attributes via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  let :view do
    Pakyow::Presenter::View.new("<div@post title=\"foo\"></div>").find(:post)
  end

  it "responds the same to attrs or attributes" do
    expect(presenter.attrs).to be(presenter.attributes)
  end

  context "string attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div@post title=\"foo\"></div>").find(:post)
      end

      it "can be read" do
        expect(presenter.attributes[:title]).to eq("foo")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div@post></div>").find(:post)
      end

      it "is nil" do
        expect(presenter.attributes[:title]).to eq(nil)
      end
    end
  end

  context "hash attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div@post style=\"color:red\"></div>").find(:post)
      end

      it "can be read" do
        expect(presenter.attributes[:style]).to eq(color: "red")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div@post></div>").find(:post)
      end

      it "is nil" do
        expect(presenter.attributes[:title]).to eq(nil)
      end
    end
  end

  context "set attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div@post class=\"foo bar\"></div>").find(:post)
      end

      it "can be read" do
        expect(presenter.attributes[:class]).to eq(Set.new([:foo, :bar]))
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div@post></div>").find(:post)
      end

      it "is nil" do
        expect(presenter.attributes[:class]).to eq(nil)
      end
    end
  end

  context "boolean attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div@post checked=\"checked\"></div>").find(:post)
      end

      it "can be read" do
        expect(presenter.attributes[:checked]).to eq(true)
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div@post></div>").find(:post)
      end

      it "is false" do
        expect(presenter.attributes[:checked]).to eq(false)
      end
    end
  end
end
