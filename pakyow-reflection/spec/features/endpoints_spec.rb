RSpec.describe "reflected endpoints" do
  include_context "reflectable app"

  let :frontend_test_case do
    "endpoints/definition"
  end

  let :reflected_app_def do
    Proc.new do
      source :posts do
        attribute :title

        has_many :comments
      end

      source :comments do
        attribute :body
      end
    end
  end

  let :data do
    Pakyow.apps.first.data
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

    it "defines the endpoint on the resource" do
      expect(Pakyow.apps.first.state(:controller).count).to eq(2)
      expect(controller(:posts).expansions).to include(:resource)

      expect(controller(:posts).routes[:get].count).to eq(1)
      expect(controller(:posts).routes[:get].count).to eq(1)
      expect(controller(:posts).routes[:get].map(&:name)).to eq([:foo])
    end
  end

  context "endpoint falls within a nested path for a resource" do
    let :frontend_test_case do
      "endpoints/within_resource_nested"
    end

    it "defines the endpoint as a child controller to the resource" do
      expect(Pakyow.apps.first.state(:controller).count).to eq(2)
      expect(controller(:posts).expansions).to include(:resource)

      expect(controller(:posts).routes[:get].count).to eq(0)
      expect(controller(:posts).children.count).to eq(1)
      expect(controller(:posts).children[0]).to be(Test::Controllers::Posts::Foo)
      expect(controller(:posts).children[0].path).to eq("/foo")
      expect(controller(:posts).children[0].routes.values.flatten.count).to eq(1)
      expect(controller(:posts).children[0].routes[:get].map(&:name)).to eq([:default])
    end
  end

  context "multiple endpoints fall within a resource" do
    let :frontend_test_case do
      "endpoints/within_resource_multiple"
    end

    it "defines each endpoint on the resource" do
      expect(Pakyow.apps.first.state(:controller).count).to eq(2)
      expect(controller(:posts).expansions).to include(:resource)

      expect(controller(:posts).routes[:get].count).to eq(1)
      expect(controller(:posts).routes[:get].map(&:name)).to eq([:bar])

      expect(controller(:posts).children.count).to eq(1)
      expect(controller(:posts).children[0]).to be(Test::Controllers::Posts::Foo)
      expect(controller(:posts).children[0].path).to eq("/foo")
      expect(controller(:posts).children[0].routes[:get].count).to eq(1)
      expect(controller(:posts).children[0].routes[:get].map(&:name)).to eq([:default])
    end
  end

  context "endpoint falls within the path for a nested resource" do
    let :frontend_test_case do
      "endpoints/within_nested_resource"
    end

    it "defines the endpoint on a nested resource located within the parent resource" do
      expect(Pakyow.apps.first.state(:controller).count).to eq(2)
      expect(controller(:posts).expansions).to include(:resource)
      expect(controller(:posts).routes.values.flatten.count).to eq(0)

      expect(controller(:posts).children.count).to eq(1)
      expect(controller(:posts).children[0]).to be(Test::Controllers::Posts::Comments)
      expect(controller(:posts).children[0].routes.values.flatten.count).to eq(1)
      expect(controller(:posts).children[0].expansions).to include(:resource)
      expect(controller(:posts).children[0].routes.values.flatten.count).to eq(1)
      expect(controller(:posts).children[0].routes[:get].map(&:name)).to eq([:foo])
      expect(controller(:posts).children[0].routes[:get].map(&:path)).to eq(["/foo"])
    end
  end

  context "view defines a binding" do
    let :frontend_test_case do
      "endpoints/binding"
    end

    let :reflected_app_def do
      Proc.new do
        source :posts do
          attribute :title
          attribute :body
        end
      end
    end

    before do
      data.posts.create(title: "foo", body: "foo body")
      data.posts.create(title: "bar", body: "bar body")
      data.posts.create(title: "baz", body: "baz body")
    end

    it "presents data for the binding" do
      expect(call("/")[2]).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article" data-id="1">
            <h1 data-b="title" data-c="article">foo</h1>
            <p data-b="body" data-c="article">foo body</p>
          </article>

          <article data-b="post" data-c="article" data-id="2">
            <h1 data-b="title" data-c="article">bar</h1>
            <p data-b="body" data-c="article">bar body</p>
          </article>

          <article data-b="post" data-c="article" data-id="3">
            <h1 data-b="title" data-c="article">baz</h1>
            <p data-b="body" data-c="article">baz body</p>
          </article>
        HTML
      )
    end
  end

  context "view defines a nested binding" do
    let :frontend_test_case do
      "endpoints/nested_binding"
    end

    let :reflected_app_def do
      Proc.new do
        source :posts do
          attribute :title
          attribute :body
        end

        source :comments do
          attribute :body
        end
      end
    end

    let :data do
      Pakyow.apps.first.data
    end

    before do
      data.posts.create(title: "foo", body: "foo body", comments: [
        # intentionally empty
      ])

      data.posts.create(title: "bar", body: "bar body", comments: [
        data.comments.create(body: "bar comment 1").one,
        data.comments.create(body: "bar comment 2").one,
        data.comments.create(body: "bar comment 3").one
      ])

      data.posts.create(title: "baz", body: "baz body", comments: [
        data.comments.create(body: "baz comment 1").one
      ])
    end

    it "presents data in both the top-level binding and nested binding" do
      expect(call("/")[2]).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article" data-id="1">
            <h1 data-b="title" data-c="article">foo</h1>
            <p data-b="body" data-c="article">foo body</p>

            <ul>
              <script type="text/template" data-b="comment" data-c="article">
                <li data-b="comment" data-c="article">
                  <p data-b="body" data-c="article">comment goes here</p>
                </li>
              </script>
            </ul>
          </article>

          <article data-b="post" data-c="article" data-id="2">
            <h1 data-b="title" data-c="article">bar</h1>
            <p data-b="body" data-c="article">bar body</p>

            <ul>
              <li data-b="comment" data-c="article" data-id="1">
                <p data-b="body" data-c="article">bar comment 1</p>
              </li>

              <li data-b="comment" data-c="article" data-id="2">
                <p data-b="body" data-c="article">bar comment 2</p>
              </li>

              <li data-b="comment" data-c="article" data-id="3">
                <p data-b="body" data-c="article">bar comment 3</p>
              </li>

              <script type="text/template" data-b="comment" data-c="article">
                <li data-b="comment" data-c="article">
                  <p data-b="body" data-c="article">comment goes here</p>
                </li>
              </script>
            </ul>
          </article>

          <article data-b="post" data-c="article" data-id="3">
            <h1 data-b="title" data-c="article">baz</h1>
            <p data-b="body" data-c="article">baz body</p>

            <ul>
              <li data-b="comment" data-c="article" data-id="4">
                <p data-b="body" data-c="article">baz comment 1</p>
              </li>

              <script type="text/template" data-b="comment" data-c="article">
                <li data-b="comment" data-c="article">
                  <p data-b="body" data-c="article">comment goes here</p>
                </li>
              </script>
            </ul>
          </article>
        HTML
      )
    end
  end

  context "view defines a form for a binding" do
    let :frontend_test_case do
      "endpoints/form"
    end

    it "sets up the form for creating" do
      expect(call("/")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="post" data-ui="form" data-c="form" class="" action="/posts" method="post">
        HTML
      )
    end
  end

  context "view defines a form within a binding" do
    let :frontend_test_case do
      "endpoints/form_within_binding"
    end

    before do
      data.posts.create(title: "foo")
    end

    it "sets up the form for creating the nested data" do
      expect(call("/")[2]).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-c="article" data-id="1">
            <h1 data-b="title" data-c="article">foo</h1>

            <form data-b="comment" data-c="article:form" action="/posts/1/comments" method="post">
        HTML
      )
    end
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
