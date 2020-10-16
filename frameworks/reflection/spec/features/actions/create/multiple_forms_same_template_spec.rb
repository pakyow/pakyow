require_relative "../shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  context "more than one form exists for the resource in the same view template" do
    let :frontend_test_case do
      "actions/create_multiple_forms_same_view_template"
    end

    let :values do
      {
        post: {
          title: "post one",
          body: "this is the first post"
        }
      }
    end

    let :path do
      "/posts"
    end

    let :form do
      super().tap do |form|
        form[:binding] = "post:form:bar"
      end
    end

    it "handles the correct form submission" do
      # The bar form only contains title, so the post shouldn't be created with a body.
      #
      expect {
        response
      }.to change {
        data.posts.count
      }.from(0).to(1)

      expect(data.posts[0].title).to eq(params[:post][:title])
      expect(data.posts[0].body).to be(nil)
    end

    it "redirects back to the form origin" do
      expect(response[0]).to eq(302)
      expect(response[1]["location"].to_s).to eq(form[:origin])
    end
  end
end
