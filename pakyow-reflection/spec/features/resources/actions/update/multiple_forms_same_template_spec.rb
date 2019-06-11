require_relative "../shared"

RSpec.describe "reflected resource update action" do
  include_context "resource action"

  context "more than one form exists for the resource in the same view template" do
    let :frontend_test_case do
      "resources/actions/update_multiple_forms_same_view_template"
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
      "/posts/#{updatable.one.id}"
    end

    let :method do
      :patch
    end

    let :form do
      {
        view_path: "/posts/edit",
        binding: "post:form:bar",
        origin: path
      }
    end

    let :updatable do
      data.posts.create
    end

    before do
      updatable
    end

    it "handles the correct form submission" do
      # The bar form only contains title, so the post shouldn't be created with a body.
      #
      expect {
        response
      }.not_to change {
        data.posts.count
      }

      expect(data.posts[0].title).to eq(params[:post][:title])
      expect(data.posts[0].body).to be(nil)
    end

    it "redirects back to the form origin" do
      expect(response[0]).to eq(302)
      expect(response[1]["location"].to_s).to eq(form[:origin])
    end
  end
end
