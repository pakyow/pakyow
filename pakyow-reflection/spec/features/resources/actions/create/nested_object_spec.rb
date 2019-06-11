require_relative "../shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  context "passed a nested object" do
    let :frontend_test_case do
      "resources/actions/create_with_nested_object"
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
      "/users"
    end

    let :form do
      super().tap do |form|
        form[:binding] = "user:form"
      end
    end

    let :reflected_app_def do
      Proc.new do
        source :users do
          has_one :link
        end
      end
    end

    it "creates the object with nested objects associated to it" do
      expect {
        response
      }.to change {
        data.users.count
      }.from(0).to(1)

      user = data.users.including(:link)[0]
      expect(user.name).to eq(values[:user][:name])

      expect(user.link.url).to eq(values[:user][:link][:url])
    end

    it "redirects back to the form origin" do
      expect(response[0]).to eq(302)
      expect(response[1]["location"].to_s).to eq(form[:origin])
    end

    context "nested object already exists" do
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

      before do
        data.links.create(url: "http://bryanp.org")
      end

      it "creates the object with nested objects associated to it" do
        expect {
          response
        }.to change {
          data.users.count
        }.from(0).to(1)

        user = data.users.including(:link)[0]
        expect(user.name).to eq(values[:user][:name])

        expect(user.link.url).to eq(values[:user][:link][:url])
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
