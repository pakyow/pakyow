RSpec.describe "form origin" do
  include_context "testable app"

  context "form is not setup explicitly" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/form" do
            render "/form"
          end
        end
      }
    end

    it "embeds the form origin" do
      response = call("/form?foo=bar")
      expect(response[0]).to eq(200)

      response_body = response[2].body.read
      expect(response_body).to include("input type=\"hidden\" name=\"form[origin]\"")

      form_origin = response_body.match(/name=\"form\[origin\]\" value=\"([^\"]+)\"/)[1]
      expect(form_origin).to eq("/form?foo=bar")
    end
  end

  context "form is setup explicitly" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        controller :default do
          get "/form" do
            render "/form"
          end
        end

        resource :posts, "/posts" do
          create do; end
        end

        presenter "/form" do
          def perform
            form(:post).create({})
          end
        end
      }
    end

    it "embeds a valid authenticity token" do
      response = call("/form?foo=bar")
      expect(response[0]).to eq(200)

      response_body = response[2].body.read
      expect(response_body).to include("input type=\"hidden\" name=\"form[origin]\"")

      form_origin = response_body.match(/name=\"form\[origin\]\" value=\"([^\"]+)\"/)[1]
      expect(form_origin).to eq("/form?foo=bar")
    end
  end
end
