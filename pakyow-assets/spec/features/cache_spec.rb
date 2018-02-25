RSpec.describe "setting cache headers" do
  include_context "testable app"

  context "cache is enabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$assets_app_boilerplate)
        config.assets.cache = true
      end
    end

    context "requested file is public, but not an asset" do
      it "responds 200" do
        expect(call("/robots.txt")[0]).to eq(200)
      end

      it "does not respond with cache headers" do
        expect(call("/robots.txt")[1]).to eq("Content-Type" => "text/plain")
      end
    end

    context "requested file is public, and is an asset" do
      it "responds 200" do
        expect(call("/assets/cache/default.css")[0]).to eq(200)
      end

      it "responds with cache headers" do
        headers = call("/assets/cache/default.css")[1]
        expect(headers["Cache-Control"]).to eq("public, max-age=31536000")
        expect(headers["Vary"]).to eq("Accept-Encoding")
        expect(headers["Last-Modified"]).to_not be_nil
        expect(headers["Age"]).to_not be_nil
      end
    end
  end

  context "cache is disabled" do
    let :app_definition do
      Proc.new do
        instance_exec(&$assets_app_boilerplate)
        config.assets.cache = false
      end
    end

    context "requested file is public, but not an asset" do
      it "responds 200" do
        expect(call("/robots.txt")[0]).to eq(200)
      end

      it "does not respond with cache headers" do
        expect(call("/robots.txt")[1]).to eq("Content-Type" => "text/plain")
      end
    end

    context "requested file is public, and is an asset" do
      it "responds 200" do
        expect(call("/assets/cache/default.css")[0]).to eq(200)
      end

      it "does not respond with cache headers" do
        headers = call("/assets/cache/default.css")[1]
        expect(headers["Cache-Control"]).to be_nil
        expect(headers["Vary"]).to be_nil
        expect(headers["Last-Modified"]).to be_nil
        expect(headers["Age"]).to be_nil
      end
    end
  end
end
