RSpec.describe "verifying that the request is from the same origin" do
  include_context "app"

  before do
    allow_any_instance_of(
      Pakyow::Security::CSRF::VerifyAuthenticityToken
    ).to receive(:allowed?).and_return(true)
  end

  describe "skipping verify_same_origin" do
    let :app_init do
      Proc.new do
        controller do
          skip_action :verify_same_origin

          post "/" do
          end
        end
      end
    end

    it "skips" do
      expect(call("/", method: :post)[0]).to eq(200)
    end
  end

  describe "overriding verify_same_origin" do
    let :app_init do
      Proc.new do
        controller do
          post "/" do
          end

          def verify_same_origin
            send "overridden"
          end
        end
      end
    end

    it "overrides" do
      expect(call("/", method: :post)[2].read).to eq("overridden")
    end
  end
end
