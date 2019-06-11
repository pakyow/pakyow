RSpec.describe "reflected resource new endpoint" do
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
      "endpoints/resource/new"
    end

    it "defines an endpoint" do
      expect(call("/posts/new")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="post" data-c="form" data-ui="form" class="" action="/posts" method="post">
        HTML
      )
    end
  end

  context "view path does not exist" do
    let :frontend_test_case do
      "endpoints/resource/new/none"
    end

    it "does not define an endpoint" do
      expect(call("/posts/new")[0]).to eq(404)
    end
  end
end
