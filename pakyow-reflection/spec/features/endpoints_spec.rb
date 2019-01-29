RSpec.describe "reflected endpoints" do
  include_context "reflectable app"

  let :frontend_test_case do
    "endpoints/definition"
  end

  def controller(name)
    Pakyow.apps.first.state(:controller).find { |controller|
      controller.__object_name.name == name
    }
  end

  it "defines a controller for each directory" do
    expect(Pakyow.apps.first.state(:controller).count).to eq(3)

    expect(controller(:foo).ancestors).to include(Test::App::Controller)
    expect(controller(:foo).path).to eq("/foo")

    expect(controller(:bar).ancestors).to include(Test::App::Controller)
    expect(controller(:bar).path).to eq("/bar")
  end

  it "includes the reflection extension" do
    expect(controller(:foo).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:bar).ancestors).to include(Pakyow::Reflection::Extension::Controller)
  end

  it "defines an endpoint for each file within the directory" do
    expect(controller(:foo).routes.values.flatten.count).to eq(2)
    expect(controller(:bar).routes.values.flatten.count).to eq(1)

    expect(controller(:foo).routes[:get][0].name).to eq(:default)
    expect(controller(:foo).routes[:get][0].path).to eq("/")

    expect(controller(:foo).routes[:get][1].name).to eq(:bar)
    expect(controller(:foo).routes[:get][1].path).to eq("/bar")

    expect(controller(:bar).routes[:get][0].name).to eq(:default)
    expect(controller(:bar).routes[:get][0].path).to eq("/")
  end

  describe "nested endpoints" do
    let :frontend_test_case do
      "endpoints/nested_definition"
    end

    it "defines a child controller for each nested directory" do
      expect(Pakyow.apps.first.state(:controller).count).to eq(2)

      expect(controller(:foo).children.count).to eq(1)
      expect(controller(:foo).children).to eq([Test::Controllers::Foo::Bar])
      expect(controller(:foo).children[0].path).to eq("/bar")
    end

    it "does not define a top level controller for a nested directory" do
      expect(controller(:bar)).to be(nil)
    end

    it "defines an endpoint for each file within the nested directory" do
      expect(controller(:foo).children[0].routes.values.flatten.count).to eq(1)
      expect(controller(:foo).children[0].routes[:get][0].name).to eq(:default)
      expect(controller(:foo).children[0].routes[:get][0].path).to eq("/")
    end
  end

  context "endpoint is for root index" do
    let :frontend_test_case do
      "endpoints/root_definition"
    end

    it "defines a root controller" do
      expect(Pakyow.apps.first.state(:controller).count).to eq(2)

      expect(controller(:root).ancestors).to include(Test::App::Controller)
      expect(controller(:root).path).to eq("/")
    end

    it "defines the endpoint" do
      expect(controller(:root).routes.values.flatten.count).to eq(1)
      expect(controller(:root).routes[:get][0].name).to eq(:default)
      expect(controller(:root).routes[:get][0].path).to eq("/")
    end
  end

  context "endpoint falls within the path for a resource" do
    let :frontend_test_case do
      "endpoints/within_resource"
    end

    it "defines the endpoint on the resource collection" do
      expect(Pakyow.apps.first.state(:controller).count).to eq(2)
      expect(controller(:posts).ancestors).to include(Pakyow::Controller)
      expect(controller(:posts).ancestors).to include(Pakyow::Routing::Extension::Resource)

      expect(controller(:posts).routes[:get].count).to eq(1)
      expect(controller(:posts).routes[:get].map(&:name)).to eq([:new])

      # TODO: pull in the tests from below
      #
      # I think we need to introduce a different code path when we're defining endpoints for resources
      # the logic is slightly different from that of a normal controller based endpoint
    end
  end

  context "endpoint falls within a nested path for a resource" do
    let :frontend_test_case do
      "endpoints/within_resource_nested"
    end

    it "defines the endpoint on the resource collection" do
      expect(Pakyow.apps.first.state(:controller).count).to eq(2)
      expect(controller(:posts).ancestors).to include(Pakyow::Controller)
      expect(controller(:posts).ancestors).to include(Pakyow::Routing::Extension::Resource)

      expect(controller(:posts).routes[:get].count).to eq(1)
      expect(controller(:posts).routes[:get].map(&:name)).to eq([:new])

      expect(controller(:posts).children.count).to eq(1)
      expect(controller(:posts).children[0]).to be(Test::Controllers::Posts::Collection)
      expect(controller(:posts).children[0].routes[:get].count).to eq(1)
      expect(controller(:posts).children[0].routes[:get].map(&:name)).to eq([:foo])
    end
  end

  context "endpoint falls within the show path for a resource" do
    let :frontend_test_case do
      "endpoints/within_resource_show"
    end

    it "defines the endpoint as a resource member" do
      expect(Pakyow.apps.first.state(:controller).count).to eq(2)
      expect(controller(:posts).ancestors).to include(Pakyow::Controller)
      expect(controller(:posts).ancestors).to include(Pakyow::Routing::Extension::Resource)
    end
  end

  context "endpoint falls within a nested path for a nested resource" do
    it "needs tests"
  end

  context "endpoint falls within the show path for a nested resource" do
    it "needs tests"
  end

  context "view defines a binding" do
    it "presents data for the binding"
  end

  context "view defines a nested binding" do
    it "presents data in both the top-level binding and nested binding"
  end

  context "view defines a form for a binding" do
    it "sets up the form for creating"
  end

  context "view defines a form within a binding" do
    it "sets up the form for creating the nested data"
  end

  context "view defines a binding that doesn't have a source" do
    it "does not define an endpoint"
  end

  context "view defines multiple bindings, one of which doesn't have a source" do
    it "defines an endpoint that presents data for bindings that have a source"
  end

  context "controller is already defined" do
    context "reflected endpoint is not defined in the existing controller" do
      it "defines the reflected endpoint"
    end

    context "endpoint is defined in the existing controller that matches the reflected endpoint" do
      it "does not override the existing endpoint"
      it "adds the reflect action to the endpoint"
    end
  end
end
