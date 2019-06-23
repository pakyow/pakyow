require_relative "../shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  context "resource is already defined" do
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

    context "reflected action is not defined in the existing resource" do
      let :reflected_app_def do
        Proc.new do
          resource :post, "/posts" do
          end
        end
      end

      it "defines the reflected action" do
        expect {
          response
        }.to change {
          data.posts.count
        }.from(0).to(1)

        expect(data.posts[0].title).to eq(params[:post][:title])
        expect(data.posts[0].body).to eq(params[:post][:body])
      end
    end

    context "action is defined in the existing resource that matches the reflected action" do
      let :reflected_app_def do
        local = self
        Proc.new do
          resource :posts, "/posts" do
            create do
              local.instance_variable_set(:@reflected_scope, reflected_scope)
              local.instance_variable_set(:@reflected_action, reflected_action)
              send "app"
            end
          end
        end
      end

      it "does not perform the reflective create" do
        expect {
          response
        }.not_to change {
          data.posts.count
        }
      end

      it "does not try to redirect" do
        expect(response[0]).to eq(200)
        expect(response[2]).to eq("app")
      end

      it "exposes reflected state" do
        response
        expect(@reflected_scope).to be_instance_of(Pakyow::Reflection::Scope)
        expect(@reflected_action).to be_instance_of(Pakyow::Reflection::Action)
      end
    end
  end
end
