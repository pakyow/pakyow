RSpec.describe "reflected resources" do
  include_context "reflectable app"

  let :posts do
    Pakyow.apps.first.state(:controller).find { |controller|
      controller.__object_name.name == :posts
    }
  end

  let :frontend_test_case do
    "resources"
  end

  it "defines a resource for each top level discovered type" do
    expect(posts.ancestors).to include(Pakyow::Controller)
    expect(posts.ancestors).to include(Pakyow::Routing::Extension::Resource)
  end

  it "includes the reflection extension" do
    expect(posts.ancestors).to include(Pakyow::Reflection::Extension::Controller)
  end

  describe "nested resources" do
    let :comments do
      posts.children[0]
    end

    it "defines a child resource for each nested discovered type" do
      expect(comments.ancestors).to include(Pakyow::Controller)
      expect(comments.ancestors).to include(Pakyow::Routing::Extension::Resource)
    end

    it "nests the resource for the nested resource within its parent" do
      expect(comments.ancestors).to include(posts)
    end

    it "does not define a top level resource for a nested type" do
      expect(Pakyow.apps.first.state(:controller).find { |controller|
        controller.__object_name.name == :comments
      }).to be(nil)
    end
  end

  context "scope does not define an action or endpoint within the resource path" do
    let :frontend_test_case do
      "resource/no_action_or_resource_endpoint"
    end

    it "does not define a resource" do
      expect(posts).to be(nil)
    end
  end
end
