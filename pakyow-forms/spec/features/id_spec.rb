RSpec.describe "form id" do
  include_context "testable app"

  context "form is not setup explicitly" do
    let :app_definition do
      Proc.new {
        instance_exec(&$forms_app_boilerplate)

        controller :default do
          get "/form" do
            render "/form"
          end
        end
      }
    end

    it "embeds the form id" do
      response = call("/form")
      expect(response[0]).to eq(200)

      response_body = response[2].body.read
      expect(response_body).to include("input type=\"hidden\" name=\"form[id]\"")

      form_id = response_body.match(/name=\"form\[id\]\" value=\"([^\"]+)\"/)[1]
      expect(form_id.length).to eq(48)
    end
  end

  context "form is setup explicitly" do
    let :app_definition do
      Proc.new {
        instance_exec(&$forms_app_boilerplate)

        controller :default do
          get "/form" do
            render "/form"
          end
        end

        resources :posts, "/posts" do
          create do; end
        end

        presenter "/form" do
          form(:post).create({})
        end
      }
    end

    it "embeds the form id" do
      response = call("/form")
      expect(response[0]).to eq(200)

      response_body = response[2].body.read
      expect(response_body).to include("input type=\"hidden\" name=\"form[id]\"")

      form_id = response_body.match(/name=\"form\[id\]\" value=\"([^\"]+)\"/)[1]
      expect(form_id.length).to eq(48)
    end
  end

  context "form is setup as a result of a submission" do
    it "embeds the same form id"
  end
end
