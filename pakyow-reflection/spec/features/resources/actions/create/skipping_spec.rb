require_relative "../shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  describe "skipping the reflected behavior" do
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

    let :reflected_app_def do
      Proc.new do
        resource :posts, "/posts" do
          skip :reflect

          create do
            send "hello"
          end
        end
      end
    end

    it "calls the route" do
      expect(response[0]).to eq(200)
      expect(response[2]).to eq("hello")
    end

    it "skips the reflected behavior" do
      expect {
        response
      }.not_to change {
        data.posts.count
      }
    end
  end
end
