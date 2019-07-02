RSpec.describe "single form endpoint: nested resource new" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/forms/single-scope/nested-resource-new"
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

  it "defines a reflected resource for the parent" do
    expect(controller(:posts)).to_not be(nil)
    expect(controller(:posts).path_to_self).to eq("/posts")
    expect(controller(:posts).expansions).to include(:resource)
    expect(controller(:posts).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:posts).routes.values.flatten.count).to eq(0)
  end

  it "defines a nested reflected resource for the view route and form action" do
    expect(controller(:posts, :comments)).to_not be(nil)
    expect(controller(:posts, :comments).path_to_self).to eq("/posts/:post_id/comments")
    expect(controller(:posts, :comments).expansions).to include(:resource)
    expect(controller(:posts, :comments).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:posts, :comments).routes.values.flatten.count).to eq(2)
  end

  it "defines a route for the view" do
    expect(controller(:posts, :comments).routes[:get][0].name).to eq(:new)
    expect(controller(:posts, :comments).routes[:get][0].path).to eq("/new")
  end

  it "defines the form action" do
    expect(controller(:posts, :comments).routes[:post][0].name).to eq(:create)
    expect(controller(:posts, :comments).routes[:post][0].path).to eq("/")
  end

  describe "behavior" do
    before do
      data.posts.create
    end

    it "sets up the form for updating" do
      expect(call("/posts/1/comments/new")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="comment:form" data-e="posts_comments_create" action="/posts/1/comments" method="post">
        HTML
      )
    end
  end
end
