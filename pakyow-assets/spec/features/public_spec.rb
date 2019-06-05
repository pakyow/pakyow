RSpec.describe "accessing public files" do
  include_context "app"

  context "public handling is enabled" do
    let :app_init do
      Proc.new do
        config.assets.public = true
      end
    end

    context "requested file exists" do
      it "responds 200" do
        expect(call("/robots.txt")[0]).to eq(200)
      end

      it "responds with the file" do
        expect(call("/robots.txt")[2]).to eq("User-agent: *\nAllow: /\n")
      end

      it "sets the content type" do
        expect(call("/robots.txt")[1]["content-type"]).to eq("text/plain")
      end
    end

    context "requested file does not exist" do
      it "responds 404" do
        expect(call("/nonexistent")[0]).to eq(404)
      end
    end

    context "requested file is of an unknown type" do
      it "responds 200" do
        expect(call("/assets/foo.bar")[0]).to eq(200)
      end

      it "responds with the file" do
        expect(call("/assets/foo.bar")[2]).to eq("foo bar\n")
      end

      it "does not set the content type" do
        expect(call("/assets/foo.bar")[1]["content-type"]).to be(nil)
      end
    end
  end

  context "public handling is disabled" do
    let :app_init do
      Proc.new do
        config.assets.public = false
      end
    end

    context "requested file exists" do
      it "responds 404" do
        expect(call("/robots.txt")[0]).to eq(404)
      end
    end

    context "requested file does not exist" do
      it "responds 404" do
        expect(call("/nonexistent")[0]).to eq(404)
      end
    end
  end
end
