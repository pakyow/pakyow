RSpec.describe "sass support" do
  require "sassc"

  include_context "app"

  it "transpiles files ending with .scss" do
    expect(call("/types-scss.css")[2].body.read).to eq("body {\n  background: #ff3333; }\n")
  end

  it "does not expose the scss file" do
    expect(call("/types-scss.scss")[0]).to eq(404)
  end
end
