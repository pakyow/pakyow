RSpec.describe "processing an asset" do
  include_context "app"

  context "app is configured to process assets" do
    let :app_init do
      Proc.new do
        config.assets.process = true
      end
    end

    context "asset exists" do
      it "responds 200" do
        expect(call("/default.css")[0]).to eq(200)
      end

      it "responds with the content type" do
        expect(call("/default.css")[1]["Content-Type"]).to eq("text/css")
      end

      it "responds with the asset" do
        expect(call("/default.css")[2].body.read).to include("body {\n  background: purple; }\n")
      end
    end

    context "asset does not exist" do
      it "responds 404" do
        expect(call("/nonexistent.css")[0]).to eq(404)
      end

      it "does not set the content type" do
        expect(call("/nonexistent.css")[1]["Content-Type"]).to eq(nil)
      end

      it "responds with an empty body" do
        expect(call("/nonexistent.css")[2].body).to be_empty
      end
    end
  end

  context "app is not configured to process assets" do
    let :app_init do
      Proc.new do
        config.assets.process = false
      end
    end

    context "asset exists" do
      it "responds 404" do
        expect(call("/default.css")[0]).to eq(404)
      end

      it "does not set the content type" do
        expect(call("/default.css")[1]["Content-Type"]).to eq(nil)
      end

      it "responds with an empty body" do
        expect(call("/default.css")[2].body).to be_empty
      end
    end

    context "asset does not exist" do
      it "responds 404" do
        expect(call("/nonexistent.css")[0]).to eq(404)
      end

      it "does not set the content type" do
        expect(call("/nonexistent.css")[1]["Content-Type"]).to eq(nil)
      end

      it "responds with an empty body" do
        expect(call("/nonexistent.css")[2].body).to be_empty
      end
    end
  end
end
