RSpec.describe "forms csrf" do
  include_context "testable app"

  context "presenter is configured to embed authenticity tokens" do
    context "form is not setup explicitly" do
      let :app_definition do
        Proc.new {
          instance_exec(&$presenter_app_boilerplate)

          configure :test do
            config.presenter.embed_authenticity_token = true
          end

          controller :default do
            get "/form" do
              $authenticity_server_id = authenticity_server_id
              render "/form"
            end
          end
        }
      end

      it "embeds a valid authenticity token" do
        response = call("/form")
        expect(response[0]).to eq(200)

        response_body = response[2].body.read
        expect(response_body).to include("input type=\"hidden\" name=\"authenticity_token\"")

        authenticity_client_id, authenticity_digest = response_body.match(/value=\"([^\"]+)\"/)[1].split(":")
        computed_digest = Pakyow::Support::MessageVerifier.digest(authenticity_client_id, key: $authenticity_server_id)

        expect(authenticity_digest).to eq(computed_digest)
      end
    end

    context "form is setup explicitly" do
      let :app_definition do
        Proc.new {
          instance_exec(&$presenter_app_boilerplate)

          configure :test do
            config.presenter.embed_authenticity_token = true
          end

          controller :default do
            get "/form" do
              $authenticity_server_id = authenticity_server_id
              render "/form"
            end
          end

          resources :posts, "/posts" do
            create do; end
          end

          presenter "/form" do
            perform do
              form(:post).create({})
            end
          end
        }
      end

      it "embeds a valid authenticity token" do
        response = call("/form")
        expect(response[0]).to eq(200)

        response_body = response[2].body.read
        expect(response_body).to include("input type=\"hidden\" name=\"authenticity_token\"")

        authenticity_client_id, authenticity_digest = response_body.match(/value=\"([^\"]+)\"/)[1].split(":")
        computed_digest = Pakyow::Support::MessageVerifier.digest(authenticity_client_id, key: $authenticity_server_id)

        expect(authenticity_digest).to eq(computed_digest)
      end
    end
  end

  context "presenter is not configured to embed authenticity tokens" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        configure :test do
          config.presenter.embed_authenticity_token = false
        end

        controller :default do
          get "/form" do
            $authenticity_server_id = authenticity_server_id
            render "/form"
          end
        end
      }
    end

    it "needs definition" do
      response = call("/form")
      expect(response[0]).to eq(200)

      response_body = response[2].body.read
      expect(response_body).not_to include("input type=\"hidden\" name=\"authenticity_token\"")
    end
  end
end
