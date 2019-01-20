RSpec.describe "embedding csrf meta tags in a rendered view" do
  include_context "app"

  context "presenter is configured to embed authenticity tokens" do
    let :app_def do
      Proc.new do
        configure :test do
          config.presenter.embed_authenticity_token = true
        end
      end
    end

    let :app_init do
      Proc.new do
        controller :default do
          get "/" do
            $connection_verifier_key = connection.verifier.key
            render "/"
          end
        end
      end
    end

    it "embeds a valid authenticity token" do
      response = call("/")
      expect(response[0]).to eq(200)

      response_body = response[2].body.read
      expect(response_body).to include("meta name=\"pw-authenticity-token\"")

      authenticity_client_id, authenticity_digest = response_body.match(/name=\"pw-authenticity-token\" content=\"([^\"]+)\"/)[1].split("--")
      computed_digest = Pakyow::Support::MessageVerifier.digest(Base64.decode64(authenticity_client_id), key: $connection_verifier_key)

      expect(authenticity_digest).to eq(computed_digest)
    end

    it "embeds the authenticity param" do
      response = call("/")
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to include("meta name=\"pw-authenticity-param\" content=\"authenticity_token\"")
    end
  end

  context "presenter is not configured to embed authenticity tokens" do
    let :app_def do
      Proc.new do
        configure :test do
          config.presenter.embed_authenticity_token = false
        end
      end
    end

    let :app_init do
      Proc.new do
        controller :default do
          get "/" do
            render "/"
          end
        end
      end
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
