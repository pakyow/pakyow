RSpec.describe "finding a significant view via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  describe "finding a top-level binding" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
    end

    context "binding exists" do
      it "returns a presenter that wraps the binding" do
        result = presenter.find(:post)
        expect(result).to be_instance_of(Pakyow::Presenter::Presenter)
        expect(result.view).to be_instance_of(Pakyow::Presenter::VersionedView)
      end
    end

    context "binding does not exist" do
      it "returns nil" do
        result = presenter.find(:nonexistent)
        expect(result).to be nil
      end
    end
  end

  describe "finding a nested binding via traversal" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\"></h1></div>")
    end

    context "binding exists" do
      it "returns a presenter that wraps the binding" do
        result = presenter.find(:post, :title)
        expect(result).to be_instance_of(Pakyow::Presenter::Presenter)
        expect(result.view).to be_instance_of(Pakyow::Presenter::VersionedView)
      end
    end

    context "binding does not exist" do
      it "returns nil" do
        result = presenter.find(:post, :nonexistent)
        expect(result).to be nil
      end
    end
  end

  describe "finding a nested binding via multiple finds" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\"></h1></div>")
    end

    context "binding exists" do
      it "returns a presenter that wraps the binding" do
        result = presenter.find(:post).find(:title)
        expect(result).to be_instance_of(Pakyow::Presenter::Presenter)
        expect(result.view).to be_instance_of(Pakyow::Presenter::VersionedView)
      end
    end

    context "binding does not exist" do
      it "returns nil" do
        result = presenter.find(:post).find(:nonexistent)
        expect(result).to be nil
      end
    end
  end

  describe "finding a deeply nested binding via traversal" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><div binding=\"comment\"><h1 binding=\"title\"></h1></div></div>")
    end

    context "binding exists" do
      it "returns a presenter that wraps the binding" do
        result = presenter.find(:post, :comment, :title)
        expect(result).to be_instance_of(Pakyow::Presenter::Presenter)
        expect(result.view).to be_instance_of(Pakyow::Presenter::VersionedView)
      end
    end

    context "binding does not exist" do
      it "returns nil" do
        result = presenter.find(:post, :comment, :nonexistent)
        expect(result).to be nil
      end
    end
  end

  describe "finding a deeply nested binding via multiple finds" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><div binding=\"comment\"><h1 binding=\"title\"></h1></div></div>")
    end

    context "binding exists" do
      it "returns a presenter that wraps the binding" do
        result = presenter.find(:post).find(:comment).find(:title)
        expect(result).to be_instance_of(Pakyow::Presenter::Presenter)
        expect(result.view).to be_instance_of(Pakyow::Presenter::VersionedView)
      end
    end

    context "binding does not exist" do
      it "returns nil" do
        result = presenter.find(:post).find(:comment).find(:nonexistent)
        expect(result).to be nil
      end
    end
  end

  describe "finding a nested binding when there's more than one match" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">one</h1></div><div binding=\"post\"><h1 binding=\"title\">two</h1></div>")
    end

    it "traverses through the first match" do
      expect(presenter.find(:post, :title).view.text).to eq("one")
    end
  end
end

RSpec.describe "finding all significant views via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  describe "finding a top-level binding" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"></div><div binding=\"post\"></div>")
    end

    context "binding exists" do
      it "returns an array of presenters wrapping the binding" do
        result = presenter.find_all(:post)
        expect(result.count).to eq(2)
        expect(result[0]).to be_instance_of(Pakyow::Presenter::Presenter)
        expect(result[1]).to be_instance_of(Pakyow::Presenter::Presenter)
      end
    end

    context "binding does not exist" do
      it "returns an empty array" do
        expect(presenter.find_all(:foo)).to eq([])
      end
    end
  end

  describe "finding a nested binding via traversal" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\"></h1><h1 binding=\"title\"></h1></div>")
    end

    context "binding exists" do
      it "returns an array of presenters wrapping the binding" do
        result = presenter.find_all(:title)
        expect(result.count).to eq(2)
        expect(result[0]).to be_instance_of(Pakyow::Presenter::Presenter)
        expect(result[1]).to be_instance_of(Pakyow::Presenter::Presenter)
      end
    end

    context "binding does not exist" do
      it "returns an empty array" do
        expect(presenter.find_all(:foo)).to eq([])
      end
    end
  end

  describe "finding a nested binding via multiple finds" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\"></h1><h1 binding=\"title\"></h1></div>")
    end

    context "binding exists" do
      it "returns an array of presenters wrapping the binding" do
        result = presenter.find_all(:post)[0].find_all(:title)
        expect(result.count).to eq(2)
        expect(result[0]).to be_instance_of(Pakyow::Presenter::Presenter)
        expect(result[1]).to be_instance_of(Pakyow::Presenter::Presenter)
      end
    end

    context "binding does not exist" do
      it "returns an empty array" do
        expect(presenter.find_all(:post)[0].find_all(:foo)).to eq([])
      end
    end
  end
end
