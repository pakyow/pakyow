RSpec.describe "single form endpoint: namespaced nested resource list" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/forms/single-scope/namespaced-nested-resource-list"
  end

  before do
    expect(controllers.count).to eq(1)
  end

  let :reflected_app_def do
    Proc.new do
      # Define this explicitly since there isn't a post scope in the view.
      #
      source :posts do
      end
    end
  end

  it "defines a top level reflected controller for the namespace" do
    expect(controller(:foo)).to_not be(nil)
    expect(controller(:foo).path_to_self).to eq("/foo")
    expect(controller(:foo).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:foo).routes.values.flatten.count).to eq(0)
  end

  it "defines a reflected resource for the parent within the namespace" do
    expect(controller(:foo, :posts)).to_not be(nil)
    expect(controller(:foo, :posts).path_to_self).to eq("/foo/posts")
    expect(controller(:foo, :posts).expansions).to include(:resource)
    expect(controller(:foo, :posts).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:foo, :posts).routes.values.flatten.count).to eq(0)
  end

  it "defines a nested reflected resource for the view route and form action" do
    expect(controller(:foo, :posts, :comments)).to_not be(nil)
    expect(controller(:foo, :posts, :comments).path_to_self).to eq("/foo/posts/:post_id/comments")
    expect(controller(:foo, :posts, :comments).expansions).to include(:resource)
    expect(controller(:foo, :posts, :comments).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:foo, :posts, :comments).routes.values.flatten.count).to eq(2)
  end

  it "defines a route for the view" do
    expect(controller(:foo, :posts, :comments).routes[:get][0].name).to eq(:list)
    expect(controller(:foo, :posts, :comments).routes[:get][0].path).to eq("/")
  end

  it "defines the form action" do
    expect(controller(:foo, :posts, :comments).routes[:post][0].name).to eq(:create)
    expect(controller(:foo, :posts, :comments).routes[:post][0].path).to eq("/")
  end

  describe "behavior" do
    before do
      data.posts.create
    end

    it "sets up the form for creating" do
      expect(call("/foo/posts/1/comments")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="comment:form" data-e="foo_posts_comments_create" action="/foo/posts/1/comments" method="post">
        HTML
      )
    end
  end
end
