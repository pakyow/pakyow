RSpec.describe "reflected resource list endpoint" do
  include_context "reflectable app"

  let :reflected_app_def do
    Proc.new do
      source :posts do
        attribute :title
        attribute :body
      end
    end
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
      "endpoints/resource/list"
    end

    it "presents the data" do
      expect(call("/posts")[2]).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article" data-id="1">
            <h1 data-b="title" data-c="article">foo</h1>
            <p data-b="body" data-c="article">foo body</p>
          </article>

          <article data-b="post" data-c="article" data-id="2">
            <h1 data-b="title" data-c="article">bar</h1>
            <p data-b="body" data-c="article">bar body</p>
          </article>

          <article data-b="post" data-c="article" data-id="3">
            <h1 data-b="title" data-c="article">baz</h1>
            <p data-b="body" data-c="article">baz body</p>
          </article>
        HTML
      )
    end
  end

  context "view path does not exist" do
    let :frontend_test_case do
      "endpoints/resource/list/none"
    end

    it "does not define an endpoint" do
      expect(call("/posts")[0]).to eq(404)
    end
  end
end
