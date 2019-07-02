RSpec.describe "single form endpoint: namespaced file" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/forms/single-scope/namespaced-file"
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

  it "defines a reflected resource for the form action" do
    expect(controller(:posts)).to_not be(nil)
    expect(controller(:posts).path_to_self).to eq("/posts")
    expect(controller(:posts).expansions).to include(:resource)
    expect(controller(:posts).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:posts).routes.values.flatten.count).to eq(1)
  end

  it "defines a route for the view" do
    expect(controller(:root).routes[:get][0].name).to eq(:foo)
    expect(controller(:root).routes[:get][0].path).to eq("/foo")
  end

  it "defines the form action" do
    expect(controller(:posts).routes[:post][0].name).to eq(:create)
    expect(controller(:posts).routes[:post][0].path).to eq("/")
  end

  describe "behavior" do
    it "sets up the form for creating" do
      expect(call("/foo")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form" data-e="posts_create" action="/posts" method="post">
        HTML
      )
    end
  end
end
