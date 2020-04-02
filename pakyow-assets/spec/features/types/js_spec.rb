RSpec.describe "js support" do
  include_context "app"

  let :app_def do
    Proc.new do
      config.assets.source_maps = false
    end
  end

  it "transpiles files ending with .js" do
    expect(call("/assets/types-js.js")[2]).to eq_sans_whitespace(
      <<~JS
        "use strict";

        function _instanceof(left, right) { if (right != null && typeof Symbol !== "undefined" && right[Symbol.hasInstance]) { return !!right[Symbol.hasInstance](left); } else { return left instanceof right; } }

        function _classCallCheck(instance, Constructor) { if (!_instanceof(instance, Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

        var Rectangle = function Rectangle(foo) {
          _classCallCheck(this, Rectangle);

          console.log(foo);
        };
      JS
    )
  end

  it "does not transpile external packs" do
    expect(call("/assets/packs/external.js")[2]).to eq_sans_whitespace(
      <<~JS
        class Rectangle {
          constructor(foo) {
            console.log(foo);
          }
        }
      JS
    )
  end
end
