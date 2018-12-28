RSpec.describe "sass support" do
  require "sassc"

  include_context "app"

  let :app_definition do
    Proc.new do
      instance_exec(&$assets_app_boilerplate)
    end
  end

  it "transpiles files ending with .sass" do
    expect(call("/types-sass.css")[2].body.read).to eq("body {\n  background: #ff3333; }\n")
  end

  it "does not expose the sass file" do
    expect(call("/types-sass.sass")[0]).to eq(404)
  end
end
