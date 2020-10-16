require_relative "../shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  context "without a valid authenticity token" do
    let :frontend_test_case do
      "actions/create"
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

    let :authenticity_token do
      "foo:bar"
    end

    it "fails to create an object for the passed values" do
      expect {
        expect(response[0]).to eq(403)
      }.not_to change {
        data.posts.count
      }
    end
  end
end
