RSpec.describe "es6 support" do
  require "babel-transpiler"

  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$assets_app_boilerplate)
    end
  end

  it "transpiles files ending with .es6" do
    expect(call("/types-es6.js")[2].body.read).to eq("\"use strict\";\n\nfunction _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError(\"Cannot call a class as a function\"); } }\n\nvar Rectangle = function Rectangle(foo) {\n  _classCallCheck(this, Rectangle);\n\n  console.log(foo);\n};")
  end

  it "does not expose the es6 file" do
    expect(call("/types-es6.es6")[0]).to eq(404)
  end
end
