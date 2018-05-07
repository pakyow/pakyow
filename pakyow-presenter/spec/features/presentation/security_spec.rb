RSpec.describe "sanitization during presentation" do
  include Pakyow::Support::SafeStringHelpers

  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  context "binding a value" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1></div>")
    end

    it "escapes the value" do
      post_view = presenter.find(:post)
      post_view.bind(title: "<blink>annoying</blink>")
      expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">&lt;blink&gt;annoying&lt;/blink&gt;</h1></div>")
    end

    context "value is marked as safe" do
      it "does not escape the value" do
        post_view = presenter.find(:post)
        post_view.bind(title: safe("<blink>annoying</blink>"))
        expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\"><blink>annoying</blink></h1></div>")
      end
    end
  end

  context "binding with a binder" do
    let :post_binder do
      Pakyow::Presenter::Binder.make :post do
        def title
          part :content do
            "<blink>#{object[:title]}</blink>"
          end

          part :title do
            "\"><script></script>"
          end
        end

        def body
          "<blink>#{object[:body]}</blink>"
        end
      end
    end

    let :presenter do
      Pakyow::Presenter::Presenter.new(view, binders: [post_binder])
    end

    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1><p binding=\"body\"></p></div>")
    end

    it "escapes the value and parts" do
      post_view = presenter.find(:post)
      post_view.present(title: "title1", body: "body1")
      expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\" title=\"&quot;&gt;&lt;script&gt;&lt;/script&gt;\">&lt;blink&gt;title1&lt;/blink&gt;</h1><p data-b=\"body\">&lt;blink&gt;body1&lt;/blink&gt;</p></div>")
    end
  end

  context "appending an html string" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
    end

    it "escapes the value" do
      post_view = presenter.find(:post)
      post_view.append("<span></span>")
      expect(presenter.to_s).to include("<div data-b=\"post\">&lt;span&gt;&lt;/span&gt;</div>")
    end

    context "value is marked as safe" do
      it "does not escape the value" do
        post_view = presenter.find(:post)
        post_view.append(safe("<span></span>"))
        expect(presenter.to_s).to include("<div data-b=\"post\"><span></span></div>")
      end
    end
  end

  context "prepending an html string" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
    end

    it "escapes the value" do
      post_view = presenter.find(:post)
      post_view.prepend("<span></span>")
      expect(presenter.to_s).to include("<div data-b=\"post\">&lt;span&gt;&lt;/span&gt;</div>")
    end

    context "value is marked as safe" do
      it "does not escape the value" do
        post_view = presenter.find(:post)
        post_view.prepend(safe("<span></span>"))
        expect(presenter.to_s).to include("<div data-b=\"post\"><span></span></div>")
      end
    end
  end

  context "inserting an html string after" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
    end

    it "escapes the value" do
      post_view = presenter.find(:post)
      post_view.after("<span></span>")
      expect(presenter.to_s).to include("<div data-b=\"post\"></div>&lt;span&gt;&lt;/span&gt;")
    end

    context "value is marked as safe" do
      it "does not escape the value" do
        post_view = presenter.find(:post)
        post_view.after(safe("<span></span>"))
        expect(presenter.to_s).to include("<div data-b=\"post\"></div><span></span>")
      end
    end
  end

  context "inserting an html string before" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
    end

    it "escapes the value" do
      post_view = presenter.find(:post)
      post_view.before("<span></span>")
      expect(presenter.to_s).to include("&lt;span&gt;&lt;/span&gt;<div data-b=\"post\"></div>")
    end

    context "value is marked as safe" do
      it "does not escape the value" do
        post_view = presenter.find(:post)
        post_view.before(safe("<span></span>"))
        expect(presenter.to_s).to include("<span></span><div data-b=\"post\"></div>")
      end
    end
  end

  context "replacing a node with an html string" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
    end

    it "escapes the value" do
      post_view = presenter.find(:post)
      post_view.replace("<span></span>")
      expect(presenter.to_s).to include("&lt;span&gt;&lt;/span&gt;")
    end

    context "value is marked as safe" do
      it "does not escape the value" do
        post_view = presenter.find(:post)
        post_view.replace(safe("<span></span>"))
        expect(presenter.to_s).to include("<span></span>")
      end
    end
  end

  context "setting an attribute value" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
    end

    it "escapes each attribute value" do
      post_view = presenter.find(:post)
      post_view.attrs[:class] = ["\"one"]
      post_view.attrs[:style] = { color: "red\">haha"}
      post_view.attrs[:title] = "\">again"
      expect(presenter.to_s).to include("<div data-b=\"post\" class=\"&quot;one\" style=\"color:red&quot;&gt;haha\" title=\"&quot;&gt;again\"></div>")
    end
  end

  context "setting a title" do
    let :view do
      Pakyow::Presenter::View.new("<head><title></title></head>")
    end

    it "strips tags from the value" do
      presenter.title = "<div>injected</div>"
      expect(presenter.to_s).to eq("<head><title>injected</title></head>")
    end
  end

  context "setting an html value" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
    end

    it "escapes the value" do
      post_view = presenter.find(:post)
      post_view.html = "<span></span>"
      expect(presenter.to_s).to include("<div data-b=\"post\">&lt;span&gt;&lt;/span&gt;</div>")
    end

    context "value is marked as safe" do
      it "does not escape the value" do
        post_view = presenter.find(:post)
        post_view.html = safe("<span></span>")
        expect(presenter.to_s).to include("<div data-b=\"post\"><span></span></div>")
      end
    end
  end
end
