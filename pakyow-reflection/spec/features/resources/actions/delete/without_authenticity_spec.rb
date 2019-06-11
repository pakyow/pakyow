require_relative "../shared"

RSpec.describe "reflected resource delete action" do
  include_context "resource action"

  context "without a valid authenticity token" do
    let :frontend_test_case do
      "resources/actions/delete"
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
      "/posts/#{deletable.one.id}"
    end

    let :method do
      :delete
    end

    let :authenticity_token do
      "foo:bar"
    end

    let :deletable do
      data.posts.create
    end

    before do
      deletable
    end

    it "fails to delete an object for the passed values" do
      expect {
        expect(response[0]).to eq(403)
      }.not_to change {
        data.posts.count
      }
    end
  end
end
