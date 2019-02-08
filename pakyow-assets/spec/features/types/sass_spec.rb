RSpec.describe "sass support" do
  require "sassc"

  include_context "app"

  let :app_def do
    Proc.new do
      config.assets.source_maps = false
    end
  end

  it "transpiles files ending with .sass" do
    expect(call("/assets/types-sass.css")[2].read).to eq("body {\n  background: #ff3333; }\n")
  end

  it "does not expose the sass file" do
    expect(call("/assets/types-sass.sass")[0]).to eq(404)
  end
end
