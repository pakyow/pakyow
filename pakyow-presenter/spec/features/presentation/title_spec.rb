RSpec.describe "view titles via presenter" do
  include_context "app"

  let :app_init do
    Proc.new do
      controller do
        get "/titles/dynamic" do
          expose :greeting, "hi"
          expose :user, { name: "bob" }
        end

        get "/titles/dynamic/channel" do
          expose :greeting, "hi", for: :title
          expose :user, { name: "bob" }, for: :title
          render "/titles/dynamic"
        end

        get "/titles/dynamic/some" do
          expose :greeting, "hi"
          render "/titles/dynamic"
        end

        get "/titles/dynamic/none" do
          render "/titles/dynamic"
        end
      end
    end
  end

  context "title contained in front matter" do
    it "sets the value" do
      expect(call("/titles")[2].body.read).to include("<title>hi</title>")
    end

    context "title contains dynamic values" do
      context "presentables exist" do
        it "sets the value" do
          expect(call("/titles/dynamic")[2].body.read).to include("<title>My Site | hi bob</title>")
        end
      end

      context "presentables are exposed for the title" do
        it "sets the value" do
          expect(call("/titles/dynamic/channel")[2].body.read).to include("<title>My Site | hi bob</title>")
        end
      end

      context "some presentables exist" do
        it "sets a partial value" do
          expect(call("/titles/dynamic/some")[2].body.read).to include("<title>My Site | hi </title>")
        end
      end

      context "no presentables exist" do
        it "sets a partial value" do
          expect(call("/titles/dynamic/none")[2].body.read).to include("<title>My Site |  </title>")
        end
      end
    end
  end

  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  describe "setting" do
    context "title node exists" do
      let :view do
        Pakyow::Presenter::View.new("<head><title></title></head>")
      end

      it "sets the value" do
        presenter.title = "foo"
        expect(presenter.to_s).to eq("<head><title>foo</title></head>")
      end
    end

    context "title node does not exist" do
      let :view do
        Pakyow::Presenter::View.new("<head></head>")
      end

      it "inserts a title node and sets the value" do
        presenter.title = "foo"
        expect(presenter.to_s).to eq("<head><title>foo</title></head>")
      end
    end
  end

  describe "getting" do
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
end
