RSpec.describe "reflected resource endpoints" do
  include_context "reflectable app"

  let :posts do
    Pakyow.apps.first.state(:controller).find { |controller|
      controller.__object_name.name == :posts
    }
  end

  let :frontend_test_case do
    "resource"
  end

  describe "list" do
    context "view path exists" do
      it "presents the data"
    end

    context "view path does not exist" do
      it "does not define an endpoint"
    end
  end

  describe "show" do
    context "view path exists" do
      it "presents the data"

      context "object can't be found" do
        it "returns 404"
      end
    end

    context "view path does not exist" do
      it "does not define an endpoint"
    end
  end

  describe "new" do
    context "view path exists" do
      it "defines an endpoint"
    end

    context "view path does not exist" do
      it "does not define an endpoint"
    end
  end

  describe "edit" do
    context "view path exists" do
      it "presents the object in the form"
    end

    context "view path does not exist" do
      it "does not define an endpoint"
    end
  end

  describe "custom endpoint within the resource path" do
    it "defines an endpoint"
  end

  describe "custom endpoint outside of resource path" do
    it "does not define an endpoint"
  end

  context "resource is already defined" do
    context "reflected endpoint is not defined in the existing resource" do
      it "defines the reflected endpoint"
    end

    context "endpoint is defined in the existing resource that matches the reflected endpoint" do
      it "does not override the existing endpoint"
      it "adds the reflect action to the endpoint"
    end
  end

  context "resource is nested" do
    it "needs tests"
  end
end
