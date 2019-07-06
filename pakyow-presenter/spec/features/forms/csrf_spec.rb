RSpec.describe "forms csrf" do
  include_context "app"

  context "presenter is configured to embed authenticity tokens" do
    context "form is not setup explicitly" do
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
            get "/form" do
              $connection_verifier_key = connection.verifier.key
              render "/form"
            end
          end
        end
      end

      it "embeds a valid authenticity token" do
        response = call("/form")
        expect(response[0]).to eq(200)

        response_body = response[2]
        expect(response_body).to include("input type=\"hidden\" name=\"pw-authenticity-token\"")

        authenticity_client_id, authenticity_digest = response_body.match(/name=\"pw-authenticity-token\" value=\"([^\"]+)\"/)[1].split("--")
        computed_digest = Pakyow::Support::MessageVerifier.digest(Base64.decode64(authenticity_client_id), key: $connection_verifier_key)

        expect(authenticity_digest).to eq(computed_digest)
      end
    end

    context "form is setup explicitly" do
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
            get "/form" do
              $connection_verifier_key = connection.verifier.key
              render "/form"
            end
          end

          resource :posts, "/posts" do
            create do; end
          end

          presenter "/form" do
            def perform
              form(:post).create
            end
          end
        end
      end

      it "embeds a valid authenticity token" do
        response = call("/form")
        expect(response[0]).to eq(200)

        response_body = response[2]
        expect(response_body).to include("input type=\"hidden\" name=\"pw-authenticity-token\"")

        authenticity_client_id, authenticity_digest = response_body.match(/name=\"pw-authenticity-token\" value=\"([^\"]+)\"/)[1].split("--")
        computed_digest = Pakyow::Support::MessageVerifier.digest(Base64.decode64(authenticity_client_id), key: $connection_verifier_key)

        expect(authenticity_digest).to eq(computed_digest)
      end
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
          get "/form" do
            $connection_verifier_key = connection.verifier.key
            render "/form"
          end
        end
      end
    end

    it "does not embed an authenticity token" do
      response = call("/form")
      expect(response[0]).to eq(200)

      response_body = response[2]
      expect(response_body).not_to include("input type=\"hidden\" name=\"authenticity_token\"")
    end
  end
end
