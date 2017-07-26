RSpec.describe "routes defined within other routes" do
  include_context "testable app"
  context "when part of a namespace is defined within another router" do
    let :app_definition do
      Proc.new {
        router :api, "/api" do
        end

        router do
          namespace :foo, "/foo" do
            get "/bar" do
              send "foo/bar"
            end

            within :api do
              get "/bar" do
                send "api/foo/bar"
              end
            end
          end
        end
      }
    end

    it "calls the route defined within the current router" do
      expect(call("/foo/bar")[2].body.first).to eq("foo/bar")
    end

    it "calls the route defined within the other router" do
      expect(call("/api/foo/bar")[2].body.first).to eq("api/foo/bar")
    end
  end

  context "when part of a resource is defined within another router" do
    let :app_definition do
      Proc.new {
        router :api, "/api" do
        end

        resource :project, "/projects" do
          list do
            send "project list"
          end

          within :api do
            list do
              send "project api list"
            end
          end
        end
      }
    end

    it "calls the route defined in the resource" do
      expect(call("/projects")[2].body.first).to eq("project list")
    end

    it "calls the route defined within the other router" do
      expect(call("/api/projects")[2].body.first).to eq("project api list")
    end
  end
end
