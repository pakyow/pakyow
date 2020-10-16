require_relative "../shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  describe "redirecting after create" do
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

    context "form origin is passed" do
      let :form do
        super().tap do |form|
          form[:origin] = origin
        end
      end

      let :origin do
        "/"
      end

      context "form origin is new" do
        let :origin do
          "/posts/new"
        end

        context "show endpoint is defined" do
          let :reflected_app_def do
            Proc.new do
              resource :posts, "/posts" do
                show
              end
            end
          end

          it "redirects to show" do
            expect(response[0]).to eq(302)
            expect(response[1]["location"].to_s).to eq("/posts/#{Pakyow.apps.first.data.posts.first.id}")
          end
        end

        context "list endpoint is defined" do
          let :reflected_app_def do
            Proc.new do
              resource :posts, "/posts" do
                list
              end
            end
          end

          it "redirects to list" do
            expect(response[0]).to eq(302)
            expect(response[1]["location"].to_s).to eq("/posts")
          end
        end

        context "both show and list endpoints are defined" do
          let :reflected_app_def do
            Proc.new do
              resource :posts, "/posts" do
                list
                show
              end
            end
          end

          it "redirects to show" do
            expect(response[0]).to eq(302)
            expect(response[1]["location"].to_s).to eq("/posts/1")
          end
        end

        context "neither the show nor list endpoints are defined" do
          it "redirects to the form origin" do
            expect(response[0]).to eq(302)
            expect(response[1]["location"].to_s).to eq(form[:origin])
          end
        end
      end

      context "form origin is something other than new" do
        let :origin do
          "/foo"
        end

        it "redirects to the form origin" do
          expect(response[0]).to eq(302)
          expect(response[1]["location"].to_s).to eq("/foo")
        end
      end
    end

    context "form origin is not passed" do
      let :form do
        super().tap do |form|
          form[:origin] = nil
        end
      end

      it "does not redirect" do
        expect(response[0]).to eq(200)
      end
    end
  end
end
