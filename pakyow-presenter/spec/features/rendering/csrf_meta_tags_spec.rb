RSpec.describe "embedding csrf meta tags in a rendered view" do
  include_context "testable app"

  context "presenter is configured to embed authenticity tokens" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        configure :test do
          config.presenter.embed_authenticity_token = true
        end

        controller :default do
          get "/" do
            $authenticity_server_id = authenticity_server_id
            render "/"
          end
        end
      }
    end

    it "embeds a valid authenticity token" do
      response = call("/")
      expect(response[0]).to eq(200)

      response_body = response[2].body.read
      expect(response_body).to include("meta name=\"pw-authenticity-token\"")

      authenticity_client_id, authenticity_digest = response_body.match(/content=\"(.*)\"/)[1].split(":")
      computed_digest = Pakyow::Support::MessageVerifier.digest(authenticity_client_id, key: $authenticity_server_id)

      expect(authenticity_digest).to eq(computed_digest)
    end

    it "embeds the authenticity param" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to include("meta name=\"pw-authenticity-param\" content=\"authenticity_token\"")
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
          get "/" do
            render "/"
          end
        end
      }
    end

    it "does not embed an authenticity token" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).not_to include("meta name=\"pw-authenticity-token\"")
    end

    it "does not embed the authenticity param" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).not_to include("meta name=\"pw-authenticity-param\" content=\"authenticity_token\"")
    end
  end
end
