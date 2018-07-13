RSpec.shared_context "loaded asset packs" do
  it "includes the stylesheet" do
    expect(call(request_path)[2].body.read).to include("<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"/assets/packs/test.css\">")
  end

  it "includes the javascript" do
    expect(call(request_path)[2].body.read).to include("<script src=\"/assets/packs/test.js\"></script>")
  end
end

RSpec.describe "autoloaded asset packs" do
  include_context "testable app"
  include_context "loaded asset packs"

  let :app_definition do
    Proc.new do
      instance_exec(&$assets_app_boilerplate)
      config.assets.autoloaded_packs = [:test]
    end
  end

  let :request_path do
    "/packs/autoload"
  end
end

RSpec.describe "asset packs included in a view" do
  include_context "testable app"
  include_context "loaded asset packs"

  let :app_definition do
    Proc.new do
      instance_exec(&$assets_app_boilerplate)
      config.assets.autoloaded_packs = []
    end
  end

  let :request_path do
    "/packs/explicit"
  end
end

RSpec.describe "asset packs for components" do
  include_context "testable app"
  include_context "loaded asset packs"

  let :app_definition do
    Proc.new do
      instance_exec(&$assets_app_boilerplate)
      config.assets.autoloaded_packs = []
    end
  end

  let :request_path do
    "/packs/component"
  end
end

RSpec.describe "missing asset packs" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$assets_app_boilerplate)
      config.assets.autoloaded_packs = [:nonexistent]
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
