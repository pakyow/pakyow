RSpec.describe "nested form endpoint: namespaced file" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/forms/nested-scope/namespaced-file"
  end

  before do
    expect(controllers.count).to eq(2)
  end

  it "defines a reflected controller for the view route" do
    expect(controller(:root)).to_not be(nil)
    expect(controller(:root).path_to_self).to eq("/")
    expect(controller(:root).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:root).routes.values.flatten.count).to eq(1)
  end

  it "defines a nested reflected resource for the form action" do
    expect(controller(:posts)).to_not be(nil)
    expect(controller(:posts).path_to_self).to eq("/posts")
    expect(controller(:posts).expansions).to include(:resource)
    expect(controller(:posts).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:posts).routes.values.flatten.count).to eq(0)

    expect(controller(:posts, :comments)).to_not be(nil)
    expect(controller(:posts, :comments).path_to_self).to eq("/posts/:post_id/comments")
    expect(controller(:posts, :comments).expansions).to include(:resource)
    expect(controller(:posts, :comments).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:posts, :comments).routes.values.flatten.count).to eq(1)
  end

  it "defines a route for the view" do
    expect(controller(:root).routes[:get][0].name).to eq(:foo)
    expect(controller(:root).routes[:get][0].path).to eq("/foo")
  end

  it "defines the form action" do
    expect(controller(:posts, :comments).routes.values.flatten.count).to eq(1)
    expect(controller(:posts, :comments).routes[:post][0].name).to eq(:create)
    expect(controller(:posts, :comments).routes[:post][0].path).to eq("/")
  end

  describe "behavior" do
    before do
      data.posts.create
      data.posts.create
      data.posts.create
    end

    it "sets up each form for creating within its parent" do
      body = call("/foo")[2]

      expect(body).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-id="1">
            <form data-b="comment:form" data-e="posts_comments_create" action="/posts/1/comments" method="post">
        HTML
      )

      expect(body).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-id="2">
            <form data-b="comment:form" data-e="posts_comments_create" action="/posts/2/comments" method="post">
        HTML
      )

      expect(body).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-id="3">
            <form data-b="comment:form" data-e="posts_comments_create" action="/posts/3/comments" method="post">
        HTML
      )
    end
  end
end
