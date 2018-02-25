RSpec.describe "sass support" do
  require "sass"

  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$assets_app_boilerplate)
    end
  end

  it "transpiles files ending with .scss" do
    expect(call("/types-scss.css")[2].body.read).to eq("body {\n  background: #ff3333; }\n")
  end

  it "does not expose the scss file" do
    expect(call("/types-scss.scss")[0]).to eq(404)
  end
end
