RSpec.describe "single form endpoint: namespaced folder" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/forms/single-scope/namespaced-folder"
  end

  before do
    expect(controllers.count).to eq(2)
  end

  it "defines a reflected controller for the view route" do
    expect(controller(:foo)).to_not be(nil)
    expect(controller(:foo).path_to_self).to eq("/foo")
    expect(controller(:foo).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:foo).routes.values.flatten.count).to eq(1)
  end

  it "defines a reflected resource for the form action" do
    expect(controller(:posts)).to_not be(nil)
    expect(controller(:posts).path_to_self).to eq("/posts")
    expect(controller(:posts).expansions).to include(:resource)
    expect(controller(:posts).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:posts).routes.values.flatten.count).to eq(1)
  end

  it "defines a route for the view" do
    expect(controller(:foo).routes[:get][0].name).to eq(:default)
    expect(controller(:foo).routes[:get][0].path).to eq("/")
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
