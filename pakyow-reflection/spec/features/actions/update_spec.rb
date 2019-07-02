require_relative "./shared"

RSpec.describe "reflected resource update action" do
  include_context "resource action"

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
      origin: "/"
    }
  end

  let :updatable do
    data.posts.create
  end

  let :nonupdatable do
    data.posts.create
  end

  before do
    updatable
    nonupdatable
  end

  it "updates the object with provided values" do
    expect {
      response
    }.not_to change {
      data.posts.count
    }

    expect(updatable.reload.one.title).to eq(params[:post][:title])
    expect(updatable.reload.one.body).to eq(params[:post][:body])
  end

  it "does not update other objects" do
    expect {
      response
    }.not_to change {
      data.posts.count
    }

    expect(nonupdatable.reload.one.title).to eq(nil)
    expect(nonupdatable.reload.one.body).to eq(nil)
  end

  it "redirects back to the form origin" do
    expect(response[0]).to eq(302)
    expect(response[1]["location"].to_s).to eq(form[:origin])
  end

  context "object to update can't be found" do
    let :path do
      "/posts/#{updatable.one.id + 100}"
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

    it "does not define an update endpoint" do
      expect(response[0]).to eq(404)
    end
  end
end
