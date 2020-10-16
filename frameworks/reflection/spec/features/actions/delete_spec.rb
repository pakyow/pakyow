require_relative "./shared"

RSpec.describe "reflected resource delete action" do
  include_context "resource action"

  let :frontend_test_case do
    "actions/delete"
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

  let :deletable do
    data.posts.create
  end

  let :nondeletable do
    data.posts.create
  end

  before do
    deletable
    nondeletable
  end

  it "deletes the object, leaving other data unaltered" do
    expect {
      response
    }.to change {
      data.posts.count
    }.from(2).to(1)
  end

  context "object to delete is not found" do
    let :path do
      "/posts/#{deletable.one.id + 100}"
    end

    it "404s" do
      expect(response[0]).to eq(404)
    end
  end

  context "view doesn't define a form for the object" do
    let :frontend_test_case do
      "actions/none"
    end

    let :reflected_app_def do
      Proc.new do
        source :posts do
          attribute :title
          attribute :body
        end
      end
    end

    it "does not define a delete endpoint" do
      expect(response[0]).to eq(404)
    end
  end
end
