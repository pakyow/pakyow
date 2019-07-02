RSpec.describe "single form endpoint: resource show other scope" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/forms/single-scope/resource-show-other-scope"
  end

  before do
    expect(controllers.count).to eq(2)
  end

  let :reflected_app_def do
    Proc.new do
      # Define this explicitly since there isn't a post scope in the view.
      #
      source :posts do
      end
    end
  end

  it "defines a reflected resource for the view route" do
    expect(controller(:posts)).to_not be(nil)
    expect(controller(:posts).path_to_self).to eq("/posts")
    expect(controller(:posts).expansions).to include(:resource)
    expect(controller(:posts).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:posts).routes.values.flatten.count).to eq(1)
  end

  it "defines a reflected resource for the form action" do
    expect(controller(:comments)).to_not be(nil)
    expect(controller(:comments).path_to_self).to eq("/comments")
    expect(controller(:comments).expansions).to include(:resource)
    expect(controller(:comments).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:comments).routes.values.flatten.count).to eq(1)
  end

  it "defines a route for the view" do
    expect(controller(:posts).routes[:get][0].name).to eq(:show)
    expect(controller(:posts).routes[:get][0].path).to eq("/:id")
  end

  it "defines the form action" do
    expect(controller(:comments).routes[:post][0].name).to eq(:create)
    expect(controller(:comments).routes[:post][0].path).to eq("/")
  end

  describe "behavior" do
    before do
      data.posts.create
    end

    it "sets up the form for creating" do
      expect(call("/posts/1")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="comment:form" data-e="comments_create" action="/comments" method="post">
        HTML
      )
    end
  end
end
