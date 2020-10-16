RSpec.describe "nested form endpoint: resource show other scope" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/forms/nested-scope/resource-show-other-scope"
  end

  before do
    expect(controllers.count).to eq(1)
  end

  it "defines a reflected resource for the view route" do
    expect(controller(:posts)).to_not be(nil)
    expect(controller(:posts).path_to_self).to eq("/posts")
    expect(controller(:posts).expansions).to include(:resource)
    expect(controller(:posts).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:posts).routes.values.flatten.count).to eq(1)
  end

  it "defines a nested reflected resource for the form action" do
    expect(controller(:posts, :comments)).to_not be(nil)
    expect(controller(:posts, :comments).path_to_self).to eq("/posts/:post_id/comments")
    expect(controller(:posts, :comments).expansions).to include(:resource)
    expect(controller(:posts, :comments).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:posts, :comments).routes.values.flatten.count).to eq(1)
  end

  it "defines a route for the view" do
    expect(controller(:posts).routes[:get][0].name).to eq(:show)
    expect(controller(:posts).routes[:get][0].path).to eq("/:id")
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
      expect(call("/posts/1")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="comment:form" data-e="posts_comments_create" action="/posts/1/comments" method="post">
        HTML
      )
    end
  end
end
