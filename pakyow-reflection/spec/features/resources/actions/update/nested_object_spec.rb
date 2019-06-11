require_relative "../shared"

RSpec.describe "reflected resource update action" do
  include_context "resource action"

  before do
    updatable
    nonupdatable
  end

  context "passed a nested object" do
    let :frontend_test_case do
      "resources/actions/update_with_nested_object"
    end

    let :values do
      {
        user: {
          name: "Ferdinand",

          link: {
            url: "https://bryanp.org"
          }
        }
      }
    end

    let :path do
      "/users/#{updatable.one.id}"
    end

    let :method do
      :patch
    end

    let :form do
      {
        view_path: "/users/edit",
        binding: "user:form",
        origin: path
      }
    end

    let :reflected_app_def do
      Proc.new do
        source :users do
          has_one :link
        end
      end
    end

    let :nonupdatable do
      data.users.create
    end

    context "object does not have a nested object" do
      let :updatable do
        data.users.create
      end

      it "updates the object" do
        expect {
          response
        }.not_to change {
          data.users.count
        }

        expect(updatable.reload.one[:name]).to eq(values[:user][:name])
      end

      it "creates the nested object" do
        expect {
          response
        }.to change {
          data.links.count
        }.by(1)

        expect(updatable.reload.including(:link).one[:link][:url]).to eq(values[:user][:link][:url])
      end

      it "does not update other objects" do
        expect {
          response
        }.not_to change {
          data.users.count
        }

        user = nonupdatable.reload.including(:link).one
        expect(user[:name]).to eq(nil)
        expect(user[:link]).to eq(nil)
      end

      it "redirects back to the form origin" do
        expect(response[0]).to eq(302)
        expect(response[1]["location"].to_s).to eq(form[:origin])
      end
    end

    context "object has a nested object" do
      let :updatable do
        data.users.create(link: data.links.create(url: "https://pakyow.com"))
      end

      let :values do
        {
          user: {
            name: "Ferdinand",

            link: {
              id: 1,
              url: "https://bryanp.org"
            }
          }
        }
      end

      it "updates the object" do
        expect {
          response
        }.not_to change {
          data.users.count
        }

        expect(updatable.reload.one[:name]).to eq(values[:user][:name])
      end

      it "updates the nested object" do
        expect {
          response
        }.not_to change {
          data.links.count
        }

        expect(updatable.reload.including(:link).one[:link][:url]).to eq(values[:user][:link][:url])
      end

      it "does not update other objects" do
        expect {
          response
        }.not_to change {
          data.users.count
        }

        user = nonupdatable.reload.including(:link).one
        expect(user[:name]).to eq(nil)
        expect(user[:link]).to eq(nil)
      end

      it "redirects back to the form origin" do
        expect(response[0]).to eq(302)
        expect(response[1]["location"].to_s).to eq(form[:origin])
      end
    end
  end
end
