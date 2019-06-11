require_relative "../shared"

RSpec.describe "reflected resource delete action" do
  include_context "resource action"

  let :frontend_test_case do
    "resources/actions/delete_with_dependents"
  end

  let :path do
    "/posts/#{deletable.one.id}"
  end

  let :method do
    :delete
  end

  let :form do
    {
      view_path: "/",
      origin: "/"
    }
  end

  let :nondeletable do
    data.posts.create
  end

  before do
    deletable
    nondeletable
  end

  context "source has dependents" do
    let :deletable do
      data.posts.create(comments: [
        data.comments.create.one,
        data.comments.create.one,
        data.comments.create.one
      ])
    end

    it "deletes the object" do
      expect {
        response
      }.to change {
        data.posts.count
      }.from(2).to(1)
    end

    it "deletes the dependent objects" do
      expect {
        response
      }.to change {
        data.comments.count
      }.from(3).to(0)
    end
  end
end
