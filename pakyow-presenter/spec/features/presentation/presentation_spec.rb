RSpec.describe "presenting data via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  let :view do
    Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1><p binding=\"body\">body goes here</p></div>")
  end

  let :post_presenter do
    presenter.find(:post)
  end

  it "presents a single object" do
    post_presenter.present(body: "foo")
    expect(presenter.to_s).to eq("<div data-b=\"post\"><p data-b=\"body\">foo</p></div>")
  end

  it "presents an array of objects" do
    post_presenter.present([{ title: "foo" }, { body: "bar" }])
    expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1></div><div data-b=\"post\"><p data-b=\"body\">bar</p></div>")
  end

  it "presents nil" do
    post_presenter.present(nil)
    expect(presenter.to_s).to eq("")
  end

  context "presenting a deeply nested data structure" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1><p binding=\"body\">body goes here</p><div binding=\"comment\"><p binding=\"body\">comment body goes here</p></div>")
    end

    it "presents recursively" do
      post_presenter.present([{ title: "foo" }, { body: "bar", comment: [{ body: "comment1" }, { body: "comment2" }] }])
      expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1></div><div data-b=\"post\"><p data-b=\"body\">bar</p><div data-b=\"comment\"><p data-b=\"body\">comment1</p></div><div data-b=\"comment\"><p data-b=\"body\">comment2</p></div></div>")
    end

    context "nested binding is singular, but the object responds to plural" do
      it "presents recursively" do
        post_presenter.present([{ title: "foo" }, { body: "bar", comments: [{ body: "comment1" }, { body: "comment2" }] }])
        expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1></div><div data-b=\"post\"><p data-b=\"body\">bar</p><div data-b=\"comment\"><p data-b=\"body\">comment1</p></div><div data-b=\"comment\"><p data-b=\"body\">comment2</p></div></div>")
      end
    end
  end

  context "presenting a changing value" do
    let :post do
      Class.new do
        def initialize
          @accessed = false
        end

        def title
          if @accessed
            "title2"
          else
            @accessed = true
            "title"
          end
        end

        def [](key)
          if respond_to?(key)
            public_send(key)
          else
            nil
          end
        end

        def include?(key)
          instance_variable_defined?(:"@#{key}") || respond_to?(key)
        end

        def value?(key)
          include?(key) && !!self[key]
        end
      end
    end

    it "transforms and binds with the same value" do
      post_presenter.present(post.new)
      expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">title</h1></div>")
    end
  end

  context "presenting a value multiple times" do
    let :view do
      Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1><h1 binding=\"title\">title goes here</h1></div>")
    end

    let :post do
      Class.new do
        def initialize
          @accessed = false
        end

        def title
          rand.to_s
        end

        def [](key)
          if respond_to?(key)
            public_send(key)
          else
            nil
          end
        end

        def include?(key)
          instance_variable_defined?(:"@#{key}") || respond_to?(key)
        end

        def value?(key)
          include?(key) && !!self[key]
        end
      end
    end

    it "presents the same value each time" do
      post_presenter.present(post.new)
      titles = post_presenter.find_all(:title).map(&:text)
      expect(titles[0]).to eq(titles[1])
    end
  end

  context "scope/prop is defined on a single node" do
    let :view do
      Pakyow::Presenter::View.new("<h1 binding=\"post.title\">title goes here</h1>")
    end

    it "presents the value" do
      post_presenter.present(title: "foo")
      expect(presenter.to_s).to eq("<h1 data-b=\"post.title\">foo</h1>")
    end
  end
end
