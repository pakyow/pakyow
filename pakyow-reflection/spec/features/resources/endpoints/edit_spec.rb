RSpec.describe "reflected resource edit endpoint" do
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
      "endpoints/resource/edit"
    end

    it "presents the object in the form" do
      response = call("/posts/2/edit")

      expect(response[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="post" data-c="form" data-ui="form" class="" action="/posts/2" method="post" data-id="2">
        HTML
      )

      expect(response[2]).to include_sans_whitespace(
        <<~HTML
          <input type="hidden" name="_method" value="patch">
        HTML
      )

      expect(response[2]).to include_sans_whitespace(
        <<~HTML
          <input type="text" data-b="title" data-c="form" name="post[title]" class="" value="bar">
        HTML
      )
    end
  end

  context "view path does not exist" do
    let :frontend_test_case do
      "endpoints/resource/edit/none"
    end

    it "does not define an endpoint" do
      expect(call("/posts/1/edit")[0]).to eq(404)
    end
  end
end
