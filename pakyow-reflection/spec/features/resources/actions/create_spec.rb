require_relative "./shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  let :frontend_test_case do
    "resources/actions/create"
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

  it "creates an object with provided values" do
    expect {
      response
    }.to change {
      data.posts.count
    }.from(0).to(1)

    expect(data.posts[0].title).to eq(params[:post][:title])
    expect(data.posts[0].body).to eq(params[:post][:body])
  end

  it "redirects back to the form origin" do
    expect(response[0]).to eq(302)
    expect(response[1]["location"].to_s).to eq(form[:origin])
  end

  context "view doesn't define a form for the object" do
    let :frontend_test_case do
      "resources/actions/none"
    end

    it "does not define a create endpoint" do
      expect(response[0]).to eq(404)
    end
  end
end
