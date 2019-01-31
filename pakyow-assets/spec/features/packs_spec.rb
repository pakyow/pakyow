RSpec.shared_context "loaded asset packs" do
  let :included_pack_name do
    "test"
  end

  it "includes the stylesheet" do
    expect(call(request_path)[2].body.read).to include("<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"/assets/packs/#{included_pack_name}.css\">")
  end

  it "includes the javascript" do
    expect(call(request_path)[2].body.read).to include("<script src=\"/assets/packs/#{included_pack_name}.js\"></script>")
  end
end

RSpec.describe "autoloaded asset packs" do
  include_context "app"
  include_context "loaded asset packs"

  let :app_init do
    Proc.new do
      config.assets.packs.autoload = [:test]
    end
  end

  let :request_path do
    "/packs/autoload"
  end
end

RSpec.describe "asset packs included in a view" do
  include_context "app"
  include_context "loaded asset packs"

  let :app_init do
    Proc.new do
      config.assets.packs.autoload = []
    end
  end

  let :request_path do
    "/packs/explicit"
  end
end

RSpec.describe "asset packs for components" do
  include_context "app"
  include_context "loaded asset packs"

  let :app_init do
    Proc.new do
      config.assets.packs.autoload = []
    end
  end

  let :request_path do
    "/packs/component"
  end
end

RSpec.describe "missing asset packs" do
  include_context "app"

  let :app_init do
    Proc.new do
      config.assets.packs.autoload = [:nonexistent]
    end
  end

  it "renders the view" do
    expect(call("/packs/autoload")[2].body.read).to include("autoload")
  end

  it "does not include the stylesheet" do
    expect(call("/packs/autoload")[2].body.read).not_to include("link")
  end

  it "does not include the javascript" do
    expect(call("/packs/autoload")[2].body.read).not_to include("script")
  end
end

RSpec.describe "versioned asset packs" do
  include_context "app"
  include_context "loaded asset packs"

  let :app_init do
    Proc.new do
      config.assets.packs.autoload = []
    end
  end

  let :request_path do
    "/packs/versioned"
  end

  let :included_pack_name do
    "versioned"
  end

  it "includes the latest js pack" do
    expect(call("/assets/packs/versioned.js")[2].body.read).to eq("\"use strict\";\n\nconsole.log(\"2.0\");")
  end

  it "includes the latest css pack" do
    expect(call("/assets/packs/versioned.css")[2].body.read).to eq("// 2.0\n")
  end
end

RSpec.describe "versioned, namespaced asset packs" do
  include_context "app"
  include_context "loaded asset packs"

  let :app_init do
    Proc.new do
      config.assets.packs.autoload = []
    end
  end

  let :request_path do
    "/packs/namespaced"
  end

  let :included_pack_name do
    "bar"
  end

  it "includes the latest js pack" do
    expect(call("/assets/packs/bar.js")[2].body.read).to eq("\"use strict\";\n\nconsole.log(\"2.0 bar\");")
  end

  it "includes the latest css pack" do
    expect(call("/assets/packs/bar.css")[2].body.read).to eq("// 2.0 bar\n")
  end
end
