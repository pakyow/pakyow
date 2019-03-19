RSpec.describe "setting cache headers" do
  include_context "app"

  context "cache is enabled" do
    let :app_init do
      Proc.new do
        config.assets.cache = true
      end
    end

    context "requested file is public, but not an asset" do
      it "responds 200" do
        expect(call("/robots.txt")[0]).to eq(200)
      end

      it "does not respond with cache headers" do
        expect(call("/robots.txt")[1]).to include("content-type" => "text/plain")
      end
    end

    context "requested file is public, and is an asset" do
      it "responds 200" do
        expect(call("/assets/cache/default.css")[0]).to eq(200)
      end

      it "responds with cache headers" do
        headers = call("/assets/cache/default.css")[1]
        expect(headers["cache-control"]).to eq(["public", "max-age=31536000"])
        expect(headers["vary"]).to eq(["accept-encoding"])
        expect(headers["last-modified"]).to_not be_nil
        expect(headers["age"]).to_not be_nil
      end
    end

    context "requested file is public, and is a pack" do
      it "responds 200" do
        expect(call("/assets/packs/test.css")[0]).to eq(200)
      end

      it "responds with cache headers" do
        headers = call("/assets/packs/test.css")[1]
        expect(headers["cache-control"]).to eq(["public", "max-age=31536000"])
        expect(headers["vary"]).to eq(["accept-encoding"])
        expect(headers["last-modified"]).to_not be_nil
        expect(headers["age"]).to_not be_nil
      end
    end
  end

  context "cache is disabled" do
    let :app_init do
      Proc.new do
        config.assets.cache = false
      end
    end

    context "requested file is public, but not an asset" do
      it "responds 200" do
        expect(call("/robots.txt")[0]).to eq(200)
      end

      it "does not respond with cache headers" do
        expect(call("/robots.txt")[1]).to include("content-type" => "text/plain")
      end
    end

    context "requested file is public, and is an asset" do
      it "responds 200" do
        expect(call("/assets/cache/default.css")[0]).to eq(200)
      end

      it "does not respond with cache headers" do
        headers = call("/assets/cache/default.css")[1]
        expect(headers["cache-control"]).to be_nil
        expect(headers["vary"]).to be_nil
        expect(headers["last-modified"]).to be_nil
        expect(headers["age"]).to be_nil
      end
    end

    context "requested file is public, and is a pack" do
      it "responds 200" do
        expect(call("/assets/packs/test.css")[0]).to eq(200)
      end

      it "does not respond with cache headers" do
        headers = call("/assets/packs/test.css")[1]
        expect(headers["cache-control"]).to be_nil
        expect(headers["vary"]).to be_nil
        expect(headers["last-modified"]).to be_nil
        expect(headers["age"]).to be_nil
      end
    end
  end
end
