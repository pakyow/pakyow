require_relative "../shared"

RSpec.describe "reflected resource create action: nested object without fields" do
  include_context "resource action"

  context "passed a nested object" do
    let :frontend_test_case do
      "actions/create_with_nested_object_without_fields"
    end

    let :values do
      {
        post: {
          title: "test title",
          body: "test title"
        }
      }
    end

    let :path do
      "/posts"
    end

    let :form do
      super().tap do |form|
        form[:binding] = "post:form"
      end
    end

    it "creates the object" do
      expect {
        response
      }.to change {
        data.posts.count
      }.from(0).to(1)
    end
  end
end
