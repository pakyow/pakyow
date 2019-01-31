RSpec.describe "minifying assets" do
  include_context "app"

  context "app is configured to minify" do
    let :app_def do
      Proc.new do
        config.assets.minify = true
      end
    end

    it "minifies sass" do
      expect(call("/types-sass.css")[2].body.read).to eq("body{background:#f33}\n")
    end

    it "minifies scss" do
      expect(call("/types-scss.css")[2].body.read).to eq("body{background:#f33}\n")
    end

    it "minifies js" do
      expect(call("/default.js")[2].body.read).to eq("\"use strict\";console.log(\"foo\"),console.log(\"bar\");")
    end
  end

  context "app is not configured to minify" do
    let :app_def do
      Proc.new do
        config.assets.minify = false
      end
    end

    it "does not minify sass" do
      expect(call("/types-sass.css")[2].body.read).to eq("body {\n  background: #ff3333; }\n")
    end

    it "does not minify scss" do
      expect(call("/types-scss.css")[2].body.read).to eq("body {\n  background: #ff3333; }\n")
    end

    it "does not minify js" do
      expect(call("/default.js")[2].body.read).to eq("\"use strict\";\n\nconsole.log(\"foo\");\nconsole.log(\"bar\");")
    end
  end
end
