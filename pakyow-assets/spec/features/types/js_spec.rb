RSpec.describe "js support" do
  require "babel-transpiler"

  include_context "app"

  it "transpiles files ending with .js" do
    expect(call("/types-js.js")[2].body.read).to eq("\"use strict\";\n\nfunction _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError(\"Cannot call a class as a function\"); } }\n\nvar Rectangle = function Rectangle(foo) {\n  _classCallCheck(this, Rectangle);\n\n  console.log(foo);\n};")
  end

  it "does not transpile external packs" do
    expect(call("/assets/packs/external.js")[2].body.read).to eq("class Rectangle {\n  constructor(foo) {\n    console.log(foo);\n  }\n}\n")
  end
end
