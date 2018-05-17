RSpec.describe "minifying assets" do
  include_context "testable app"

  context "app is configured to minify" do
    let :app_definition do
      Proc.new do
        instance_exec(&$assets_app_boilerplate)
        config.assets.minify = true
      end
    end

    it "minifies css" do
      expect(call("/default.css")[2].body.read).to eq("body{background:purple}")
    end

    it "minifies js" do
      expect(call("/default.js")[2].body.read).to eq("console.log(\"foo\"),console.log(\"bar\");")
    end
  end

  context "app is not configured to minify" do
    let :app_definition do
      Proc.new do
        instance_exec(&$assets_app_boilerplate)
        config.assets.minify = false
      end
    end

    it "does not minify css" do
      expect(call("/default.css")[2].body.read).to eq("body {\n  background: purple;\n}\n")
    end

    it "does not minify js" do
      expect(call("/default.js")[2].body.read).to eq("console.log(\"foo\");\nconsole.log(\"bar\");\n")
    end
  end
end
