require "pakyow/assets/scripts/babel"

RSpec.describe Pakyow::Assets::Scripts::Babel do
  let(:code) {
    <<~CODE
      class Rectangle {
        constructor(foo) {
          console.log(foo);
        }
      }
    CODE
  }

  after do
    described_class.destroy
  end

  it "transforms" do
    expect(described_class.transform(code, presets: ["es2015"])["code"]).to eq_sans_whitespace(
      <<~CODE
        "use strict";

        function _instanceof(left, right) { if (right != null && typeof Symbol !== "undefined" && right[Symbol.hasInstance]) { return !!right[Symbol.hasInstance](left); } else { return left instanceof right; } }

        function _classCallCheck(instance, Constructor) { if (!_instanceof(instance, Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

        var Rectangle = function Rectangle(foo) {
          _classCallCheck(this, Rectangle);

          console.log(foo);
        };
      CODE
    )
  end

  describe "option remapping" do
    before do
      described_class.instance_variable_set(:@__context, context)
    end

    let(:context) {
      double(call: nil)
    }

    let(:options) {
      {
        source_map: {}
      }
    }

    it "camelizes options" do
      expect(context).to receive(:call) do |function, code, passed_options|
        expect(passed_options).to include("sourceMap")
      end

      described_class.transform(code, **options)
    end
  end
end
