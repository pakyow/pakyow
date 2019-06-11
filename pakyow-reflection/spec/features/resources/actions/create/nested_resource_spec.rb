require_relative "../shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  context "resource is nested" do
    let :frontend_test_case do
      "resources/actions/create_nested_scope"
    end

    before do
      data.posts.create
    end

    let :values do
      {
        comment: {
          body: "comment one"
        }
      }
    end

    let :path do
      "/posts/#{data.posts[0].id}/comments"
    end

    let :form do
      super().tap do |form|
        form[:binding] = "post:article:form"
        form[:view_path] = "/posts/show"
      end
    end

    it "creates an object with provided values and associates to the parent object" do
      expect {
        response
      }.to change {
        data.comments.count
      }.from(0).to(1)

      comment = data.comments.including(:post)[0]
      expect(comment.body).to eq(values[:comment][:body])
      expect(comment.post).to eq(data.posts[0])
    end

    it "redirects back to the form origin" do
      expect(response[0]).to eq(302)
      expect(response[1]["location"].to_s).to eq(form[:origin])
    end

    context "parent object can't be found" do
      let :path do
        "/posts/#{data.posts[0].id + 1}/comments"
      end

      it "returns 404" do
        expect {
          expect(response[0]).to eq(404)
        }.not_to change {
          data.comments.count
        }
      end
    end
  end
end
