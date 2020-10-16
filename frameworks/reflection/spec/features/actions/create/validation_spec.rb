require_relative "../shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  describe "validating the action" do
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

    context "passed some attributes" do
      let :params do
        super().tap do |params|
          params[:post].delete(:body)
        end
      end

      it "succeeds, setting passed values" do
        expect {
          response
        }.to change {
          Pakyow.apps.first.data.posts.count
        }.from(0).to(1)

        post = Pakyow.apps.first.data.posts.first
        expect(post.title).to eq(params[:post][:title])
        expect(post.body).to be(nil)
      end

      it "redirects back to the form origin" do
        expect(response[0]).to eq(302)
        expect(response[1]["location"].to_s).to eq(form[:origin])
      end
    end

    context "passed an attribute not present in the form" do
      let :reflected_app_def do
        Proc.new do
          source :posts do
            attribute :published, :boolean, default: false
          end
        end
      end

      let :params do
        super().tap do |params|
          params[:post][:published] = true
        end
      end

      it "succeeds, ignoring the unexpected value" do
        expect {
          response
        }.to change {
          Pakyow.apps.first.data.posts.count
        }.from(0).to(1)

        expect(Pakyow.apps.first.data.posts.first.published).to be(false)
      end

      it "redirects back to the form origin" do
        expect(response[0]).to eq(302)
        expect(response[1]["location"].to_s).to eq(form[:origin])
      end
    end

    context "passed no attributes" do
      let :params do
        super().tap do |params|
          params[:post] = {}
        end
      end

      it "succeeds, setting passed values" do
        expect {
          response
        }.to change {
          Pakyow.apps.first.data.posts.count
        }.from(0).to(1)

        post = Pakyow.apps.first.data.posts.first
        expect(post.title).to eq(nil)
        expect(post.body).to be(nil)
      end

      it "redirects back to the form origin" do
        expect(response[0]).to eq(302)
        expect(response[1]["location"].to_s).to eq(form[:origin])
      end
    end

    context "type is not passed in params" do
      let :params do
        super().tap do |params|
          params.delete(:post)
        end
      end

      it "fails" do
        expect {
          expect(response[0]).to eq(400)
        }.not_to change {
          Pakyow.apps.first.data.posts.count
        }
      end
    end

    describe "required attributes" do
      let :frontend_test_case do
        "actions/required_create"
      end

      context "passed the required attribute" do
        it "succeeds, setting passed values" do
          expect {
            response
          }.to change {
            Pakyow.apps.first.data.posts.count
          }.from(0).to(1)

          post = Pakyow.apps.first.data.posts.first
          expect(post.title).to eq(params[:post][:title])
          expect(post.body).to eq(params[:post][:body])
        end

        it "redirects back to the form origin" do
          expect(response[0]).to eq(302)
          expect(response[1]["location"].to_s).to eq(form[:origin])
        end
      end

      context "required attribute is missing" do
        let :params do
          super().tap do |params|
            params[:post].delete(:body)
          end
        end

        it "fails" do
          expect {
            expect(response[0]).to eq(400)
          }.not_to change {
            Pakyow.apps.first.data.posts.count
          }
        end
      end
    end

    describe "attributes with a pattern" do
      it "needs tests"
    end

    describe "attributes with a min lenth" do
      it "needs tests"
    end

    describe "attributes with a max length" do
      it "needs tests"
    end

    describe "attributes with a min and max length" do
      it "needs tests"
    end

    describe "email attributes" do
      it "needs tests"
    end

    describe "tel attributes" do
      it "needs tests"
    end

    describe "url attributes" do
      it "needs tests"
    end
  end
end
