require_relative "../shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  context "passed a value list" do
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

    context "values are for an attribute" do
      let :frontend_test_case do
        "actions/create_with_value_list_as_attribute"
      end

      let :values do
        {
          user: {
            name: "Ferdinand",

            links: [
              "https://bryanp.org",
              "https://metabahn.com",
              "https://pakyow.com"
            ]
          }
        }
      end

      let :path do
        "/users"
      end

      let :form do
        super().tap do |form|
          form[:binding] = "user:form"
        end
      end

      it "creates the object with the value list" do
        expect {
          response
        }.to change {
          data.users.count
        }.from(0).to(1)

        expect(data.users[0].name).to eq(values[:user][:name])
        expect(data.users[0].links).to eq(values[:user][:links].inspect)
      end

      it "redirects back to the form origin" do
        expect(response[0]).to eq(302)
        expect(response[1]["location"].to_s).to eq(form[:origin])
      end
    end

    context "values are for nested objects" do
      let :frontend_test_case do
        "actions/create_with_value_list_as_object"
      end

      let :values do
        {
          user: {
            name: "Ferdinand",

            links: [
              { url: "https://bryanp.org" },
              { url: "https://metabahn.com" },
              { url: "https://pakyow.com" }
            ]
          }
        }
      end

      let :path do
        "/users"
      end

      let :form do
        super().tap do |form|
          form[:binding] = "user:form"
        end
      end

      it "creates the object with nested objects associated to it" do
        expect {
          response
        }.to change {
          data.users.count
        }.from(0).to(1)

        user = data.users.including(:links)[0]
        expect(user.name).to eq(values[:user][:name])

        expect(user.links.count).to eq(3)
        expect(user.links[0].url).to eq(values[:user][:links][0][:url])
        expect(user.links[1].url).to eq(values[:user][:links][1][:url])
        expect(user.links[2].url).to eq(values[:user][:links][2][:url])
      end

      it "redirects back to the form origin" do
        expect(response[0]).to eq(302)
        expect(response[1]["location"].to_s).to eq(form[:origin])
      end

      context "objects already exists" do
        let :values do
          {
            user: {
              name: "Ferdinand",

              links: [
                { id: 1, url: "https://bryanp.org" }
              ]
            }
          }
        end

        before do
          data.links.create(url: "http://bryanp.org")
        end

        it "creates the object with nested objects associated to it" do
          expect {
            response
          }.to change {
            data.users.count
          }.from(0).to(1)

          user = data.users.including(:links)[0]
          expect(user.name).to eq(values[:user][:name])

          expect(user.links.count).to eq(1)
          expect(user.links[0].url).to eq(values[:user][:links][0][:url])
        end

        it "updates the existing object instead of creating another one" do
          expect {
            response
          }.not_to change {
            data.links.count
          }
        end

        it "redirects back to the form origin" do
          expect(response[0]).to eq(302)
          expect(response[1]["location"].to_s).to eq(form[:origin])
        end
      end
    end
  end
end
