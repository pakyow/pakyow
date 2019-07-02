require_relative "../shared"

RSpec.describe "reflected resource delete action" do
  include_context "resource action"

  describe "skipping the reflected behavior" do
    let :frontend_test_case do
      "actions/delete"
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

    let :reflected_app_def do
      Proc.new do
        resource :posts, "/posts" do
          skip :reflect

          delete do
            send "hello"
          end
        end
      end
    end

    let :deletable do
      data.posts.create
    end

    before do
      deletable
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
