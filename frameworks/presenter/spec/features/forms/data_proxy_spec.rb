require "sqlite3"
require "pakyow/data"

RSpec.describe "setting up a form for a data proxy" do
  include_context "app"

  let :app_def do
    Proc.new do
      resource :posts, "/posts" do
        new do
          expose "post:form", data.posts
          render "/form"
        end

        create do
        end
      end

      source :posts, connection: :memory do
        attribute :title
      end
    end
  end

  let :data do
    Pakyow.apps.first.data
  end

  before do
    data.posts.create(title: "foo")
    data.posts.create(title: "bar")
  end

  context "data proxy query returns more than one result" do
    it "sets up the form for the first one" do
      expect(call("/posts/new")[2]).to include_sans_whitespace(
        <<~HTML
          <input data-b="title" type="text" name="post[title]" value="foo">
        HTML
      )
    end
  end
end
