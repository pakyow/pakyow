RSpec.describe "view titles via presenter" do
  include_context "app"

  let :app_def do
    Proc.new do
      controller do
        get "/titles/dynamic" do
          expose :greeting, "hi"
          expose :user, { name: "bob" }
        end

        get "/titles/dynamic/channel" do
          expose "greeting:title", "hi"
          expose "user:title", { name: "bob" }
          render "/titles/dynamic"
        end

        get "/titles/dynamic/some" do
          expose :greeting, "hi"
          render "/titles/dynamic"
        end

        get "/titles/dynamic/none" do
          render "/titles/dynamic"
        end

        get "/titles/dynamic/unsafe" do
          expose :greeting, "hi <script>alert('hacked')</script>"
          expose :user, { name: "bob" }
          render "/titles/dynamic"
        end

        get "/titles/entities" do
          expose :greeting, "hi"
          expose :user, { name: "bob" }
        end
      end
    end
  end

  context "title contained in front matter" do
    it "sets the value" do
      expect(call("/titles")[2]).to include("<title>hi</title>")
    end

    context "title contains dynamic values" do
      context "presentables exist" do
        it "sets the value" do
          expect(call("/titles/dynamic")[2]).to include("<title>My Site | hi bob</title>")
        end
      end

      context "presentables are exposed for the title" do
        it "sets the value" do
          expect(call("/titles/dynamic/channel")[2]).to include("<title>My Site | hi bob</title>")
        end
      end

      context "some presentables exist" do
        it "sets a partial value" do
          expect(call("/titles/dynamic/some")[2]).to include("<title>My Site | hi </title>")
        end
      end

      context "no presentables exist" do
        it "sets a partial value" do
          expect(call("/titles/dynamic/none")[2]).to include("<title>My Site |  </title>")
        end
      end

      context "value is unsafe" do
        it "escapes the value" do
          expect(call("/titles/dynamic/unsafe")[2]).to include("<title>My Site | hi &lt;script&gt;alert(&#39;hacked&#39;)&lt;/script&gt; bob</title>")
        end
      end
    end

    context "title contains html entities" do
      it "does not escape the entities" do
        expect(call("/titles/entities")[2]).to include("<title>hi &amp; bye</title>")
      end
    end
  end

  let :presenter do
    Pakyow::Presenter::Presenter.new(view, app: Pakyow.apps[0])
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
