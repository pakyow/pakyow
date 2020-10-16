require_relative "../shared"

RSpec.describe "reflected resource update action" do
  include_context "resource action"

  context "without a valid authenticity token" do
    let :frontend_test_case do
      "actions/update"
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
        binding: "post:form",
        origin: path
      }
    end

    let :authenticity_token do
      "foo:bar"
    end

    let :updatable do
      data.posts.create
    end

    before do
      updatable
    end

    it "fails to update an object for the passed values" do
      expect {
        expect(response[0]).to eq(403)
      }.not_to change {
        data.posts.count
      }
    end
  end
end
