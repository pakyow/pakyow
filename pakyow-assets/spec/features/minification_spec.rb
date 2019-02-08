RSpec.describe "minifying assets" do
  include_context "app"

  let :app_def do
    local = self

    Proc.new do
      config.assets.source_maps = false
      config.assets.minify = local.minify
    end
  end

  context "app is configured to minify" do
    let :minify do
      true
    end

    it "minifies sass" do
      expect(call("/assets/types-sass.css")[2].read).to eq("body{background:#f33}\n")
    end

    it "minifies scss" do
      expect(call("/assets/types-scss.css")[2].read).to eq("body{background:#f33}\n")
    end

    it "minifies js" do
      expect(call("/assets/default.js")[2].read).to eq("\"use strict\";console.log(\"foo\"),console.log(\"bar\");")
    end

    it "minifies external js" do
      expect(call("/assets/packs/external-transpiled.js")[2].read).to eq_sans_whitespace(
        <<~MINIFIED
          "use strict";function _instanceof(n,a){return null!=a&&"undefined"!=typeof Symbol&&a[Symbol.hasInstance]?a[Symbol.hasInstance](n):n instanceof a}function _classCallCheck(n,a){if(!_instanceof(n,a))throw new TypeError("Cannot call a class as a function")}var Rectangle=function Rectangle(n){_classCallCheck(this,Rectangle),console.log(n)};
        MINIFIED
      )
    end
  end

  context "app is not configured to minify" do
    let :minify do
      false
    end

    it "does not minify sass" do
      expect(call("/assets/types-sass.css")[2].read).to eq("body {\n  background: #ff3333; }\n")
    end

    it "does not minify scss" do
      expect(call("/assets/types-scss.css")[2].read).to eq("body {\n  background: #ff3333; }\n")
    end

    it "does not minify js" do
      expect(call("/assets/default.js")[2].read).to eq("\"use strict\";\n\nconsole.log(\"foo\");\nconsole.log(\"bar\");")
    end
  end
end
