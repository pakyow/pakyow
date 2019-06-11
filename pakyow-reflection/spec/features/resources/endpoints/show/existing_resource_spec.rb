RSpec.describe "reflected resource show endpoint" do
  include_context "reflectable app"

  let :frontend_test_case do
    "endpoints/resource/show"
  end

  let :data do
    Pakyow.apps.first.data
  end

  before do
    data.posts.create(title: "foo", body: "foo body")
    data.posts.create(title: "bar", body: "bar body")
    data.posts.create(title: "baz", body: "baz body")
  end

  context "reflected action is not defined in the existing resource" do
    let :reflected_app_def do
      Proc.new do
        source :posts do
          attribute :title
          attribute :body
        end

        resource :posts, "/posts" do
          # intentionally empty
        end
      end
    end

    it "defines the reflected endpoint"
  end

  context "endpoint is defined in the existing resource that matches the reflected endpoint" do
    context "existing endpoint exposes data" do
      it "presents the data exposed by the existing endpoint"
    end

    context "existing endpoint exposes data to a variation of the binding" do
      it "presents the data exposed by the existing endpoint"
    end

    context "existing endpoint does not expose data" do
      it "calls the route"
      it "presents the data exposed by the reflection"
    end

    context "existing endpoint explicitly renders without exposing data" do
      it "presents the data exposed by the reflection"
    end
  end
end
