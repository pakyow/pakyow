RSpec.describe "reflected resource show endpoint" do
  include_context "reflectable app"

  let :reflected_app_def do
    Proc.new do
      source :posts do
        attribute :title
        attribute :body
      end
    end
  end

  let :posts do
    Pakyow.apps.first.state(:controller).find { |controller|
      controller.__object_name.name == :posts
    }
  end

  let :data do
    Pakyow.apps.first.data
  end

  before do
    data.posts.create(title: "foo", body: "foo body")
    data.posts.create(title: "bar", body: "bar body")
    data.posts.create(title: "baz", body: "baz body")
  end

  context "view path exists" do
    let :frontend_test_case do
      "endpoints/resource/show"
    end

    it "presents the data" do
      response = call("/posts/#{data.posts.all.to_a[1].id}")

      expect(response[2]).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article" data-id="2">
            <h1 data-b="title" data-c="article">bar</h1>
            <p data-b="body" data-c="article">bar body</p>
          </article>
        HTML
      )

      expect(response[2]).not_to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article" data-id="1">
            <h1 data-b="title" data-c="article">foo</h1>
            <p data-b="body" data-c="article">foo body</p>
          </article>
        HTML
      )

      expect(response[2]).not_to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article" data-id="3">
            <h1 data-b="title" data-c="article">baz</h1>
            <p data-b="body" data-c="article">baz body</p>
          </article>
        HTML
      )
    end

    context "object can't be found" do
      it "returns 404" do
        expect(call("/posts/42")[0]).to eq(404)
      end
    end
  end

  context "view path does not exist" do
    let :frontend_test_case do
      "endpoints/resource/show/none"
    end

    it "does not define an endpoint" do
      expect(call("/posts/1")[0]).to eq(404)
    end
  end
end
