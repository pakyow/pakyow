RSpec.describe "view versioning via presenter" do
  before do
    allow(Pakyow).to receive(:env?).with(:prototype).and_return(true)
  end

  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  context "when a version is unspecified" do
    context "when there is one unversioned view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\"></h1></div>")
      end

      it "renders it" do
        expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\"></h1></div>")
      end
    end

    context "when there are multiple views, none of them versioned" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">one</h1></div><div binding=\"post\"><h1 binding=\"title\">two</h1></div>")
      end

      it "renders both of them" do
        expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">one</h1></div><div data-b=\"post\"><h1 data-b=\"title\">two</h1></div>")
      end
    end

    context "when there are multiple views, one of them being versioned" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">one</h1></div><div binding=\"post\" version=\"two\"><h1 binding=\"title\">two</h1></div>")
      end

      it "renders only the first one" do
        expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">one</h1></div>")
      end
    end

    context "when there is only a default version" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" version=\"default\"><h1 binding=\"title\">default</h1></div>")
      end

      it "renders the default" do
        expect(presenter.to_s).to eq("<div data-b=\"post\" data-v=\"default\"><h1 data-b=\"title\">default</h1></div>")
      end
    end

    context "when there are multiple versions, including a default" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" version=\"one\"><h1 binding=\"title\">one</h1></div><div binding=\"post\" version=\"default\"><h1 binding=\"title\">default</h1></div>")
      end

      it "renders only the default" do
        expect(presenter.to_s).to eq("<div data-b=\"post\" data-v=\"default\"><h1 data-b=\"title\">default</h1></div>")
      end
    end

    context "when there are multiple versions, without a default" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" version=\"one\"><h1 binding=\"title\">one</h1></div><div binding=\"post\" version=\"two\"><h1 binding=\"title\">two</h1></div>")
      end

      it "renders neither" do
        expect(presenter.to_s).to eq("")
      end
    end
  end

  context "when rendering without cleaning" do
    context "when a version is unspecified" do
      context "when there is one unversioned view" do
        let :view do
          Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\"></h1></div>")
        end

        it "renders it" do
          expect(presenter.view.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\"></h1></div>")
        end
      end

      context "when there are multiple views, none of them versioned" do
        let :view do
          Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">one</h1></div><div binding=\"post\"><h1 binding=\"title\">two</h1></div>")
        end

        it "renders both of them" do
          expect(presenter.view.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">one</h1></div><div data-b=\"post\"><h1 data-b=\"title\">two</h1></div>")
        end
      end

      context "when there are multiple views, one of them being versioned" do
        let :view do
          Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">one</h1></div><div binding=\"post\" version=\"two\"><h1 binding=\"title\">two</h1></div>")
        end

        it "renders both of them" do
          expect(presenter.view.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">one</h1></div><div data-b=\"post\" data-v=\"two\"><h1 data-b=\"title\">two</h1></div>")
        end
      end

      context "when there is only a default version" do
        let :view do
          Pakyow::Presenter::View.new("<div binding=\"post\" version=\"default\"><h1 binding=\"title\">default</h1></div>")
        end

        it "renders the default" do
          expect(presenter.view.to_s).to eq("<div data-b=\"post\" data-v=\"default\"><h1 data-b=\"title\">default</h1></div>")
        end
      end

      context "when there are multiple versions, including a default" do
        let :view do
          Pakyow::Presenter::View.new("<div binding=\"post\" version=\"one\"><h1 binding=\"title\">one</h1></div><div binding=\"post\" version=\"default\"><h1 binding=\"title\">default</h1></div>")
        end

        it "renders all of them" do
          expect(presenter.view.to_s).to eq("<div data-b=\"post\" data-v=\"one\"><h1 data-b=\"title\">one</h1></div><div data-b=\"post\" data-v=\"default\"><h1 data-b=\"title\">default</h1></div>")
        end
      end

      context "when there are multiple versions, without a default" do
        let :view do
          Pakyow::Presenter::View.new("<div binding=\"post\" version=\"one\"><h1 binding=\"title\">one</h1></div><div binding=\"post\" version=\"two\"><h1 binding=\"title\">two</h1></div>")
        end

        it "renders all of them" do
          expect(presenter.view.to_s).to eq("<div data-b=\"post\" data-v=\"one\"><h1 data-b=\"title\">one</h1></div><div data-b=\"post\" data-v=\"two\"><h1 data-b=\"title\">two</h1></div>")
        end
      end
    end
  end

  context "when a version is used" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\" version=\"default\"><h1 binding=\"title\">default</h1></div><div binding=\"post\" version=\"two\"><h1 binding=\"title\">two</h1></div>")
    end

    before do
      presenter.find(:post).use(:two)
    end

    it "only renders the used version" do
      expect(presenter.to_s).to eq("<div data-b=\"post\" data-v=\"two\"><h1 data-b=\"title\">two</h1></div>")
    end

    context "when the used version is missing" do
      before do
        presenter.find(:post).use(:three)
      end

      it "renders nothing" do
        expect(presenter.to_s).to eq("")
      end
    end
  end

  context "when using versioned props inside of an unversioned scope" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\" version=\"default\">default</h1><h1 binding=\"title\" version=\"two\">two</h1></div>")
    end

    before do
      presenter.find(:post, :title).use(:two)
    end

    it "renders appropriately" do
      expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\" data-v=\"two\">two</h1></div>")
    end
  end

  context "when using versioned props inside of a versioned scope" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\" version=\"one\"><h1 binding=\"title\">one</h1></div><div binding=\"post\" version=\"two\"><h1 binding=\"title\" version=\"one\">one</h1><h1 binding=\"title\" version=\"two\">two</h1></div>")
    end

    before do
      presenter.find(:post).use(:two).find(:title).use(:two)
    end

    it "renders appropriately" do
      expect(presenter.to_s).to eq("<div data-b=\"post\" data-v=\"two\"><h1 data-b=\"title\" data-v=\"two\">two</h1></div>")
    end
  end

  describe "finding a version" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\" version=\"default\"><h1 binding=\"title\">default</h1></div><div binding=\"post\" version=\"two\"><h1 binding=\"title\">two</h1></div>")
    end

    let :versioned do
      presenter.find(:post).versioned(:two)
    end

    it "returns the view matching the version" do
      expect(versioned).to be_instance_of(Pakyow::Presenter::Presenter)
      expect(versioned.version).to eq(:two)
      expect(versioned.to_s).to eq("<div data-b=\"post\" data-v=\"two\"><h1 data-b=\"title\">two</h1></div>")
    end

    context "match is not found" do
      it "returns nil" do
        expect(presenter.find(:post).versioned(:nonexistent)).to be(nil)
      end
    end
  end

  describe "presenting a versioned view" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\" version=\"default\"><h1 binding=\"title\">first</h1></div><div binding=\"post\" version=\"two\"><h1 binding=\"title\">two</h1></div>")
    end

    let :data do
      [{ title: "default" }, { title: "three" }, { title: "two" }]
    end

    it "presents the default version" do
      presenter.find(:post).present(data)
      expect(presenter.to_s).to eq("<div data-b=\"post\" data-v=\"default\"><h1 data-b=\"title\">default</h1></div><div data-b=\"post\" data-v=\"default\"><h1 data-b=\"title\">three</h1></div><div data-b=\"post\" data-v=\"default\"><h1 data-b=\"title\">two</h1></div>")
    end

    context "using versions during presentation" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" version=\"default\" title=\"default\"><h1 binding=\"title\">default</h1></div><div binding=\"post\" version=\"two\" title=\"two\"><h1 binding=\"title\">two</h1></div><div binding=\"post\" version=\"three\" title=\"three\"><h1 binding=\"title\">three</h1></div>")
      end

      it "uses a version for each object" do
        presenter.find(:post).present(data) do |view, object|
          view.use(object[:title])
        end

        expect(presenter.to_s).to eq("<div data-b=\"post\" data-v=\"default\" title=\"default\"><h1 data-b=\"title\">default</h1></div><div data-b=\"post\" data-v=\"three\" title=\"three\"><h1 data-b=\"title\">three</h1></div><div data-b=\"post\" data-v=\"two\" title=\"two\"><h1 data-b=\"title\">two</h1></div>")
      end
    end

    context "empty version exists, and data is empty" do
      let :view do
        Pakyow::Presenter::View.new("<body><div binding=\"post\" version=\"empty\">no posts here</div><div binding=\"post\"><h1 binding=\"title\">post title</h1></div></body>")
      end

      before do
        presenter.find(:post).present([])
      end

      it "renders the empty version" do
        expect(presenter.to_s).to eq("<body><div data-b=\"post\" data-v=\"empty\">no posts here</div></body>")
      end
    end
  end
end
