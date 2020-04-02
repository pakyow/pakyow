require "pakyow/assets/scripts/terser"

RSpec.describe Pakyow::Assets::Scripts::Terser do
  let(:code) {
    "function add(first, second) { return first + second; }"
  }

  after do
    described_class.destroy
  end

  it "minifies" do
    expect(described_class.minify(code)["code"]).to eq("function add(n,d){return n+d}")
  end

  describe "source maps" do
    it "generates a source map" do
      options = {
        sourceMap: {
          filename: "out.js",
          url: "out.js.map"
        }
      }

      expect(described_class.minify({ "foo.js" => code }, options)["map"]).to eq_sans_whitespace <<~MAP
        {"version":3,"sources":["foo.js"],"names":["add","first","second"],"mappings":"AAAA,SAASA,IAAIC,EAAOC,GAAU,OAAOD,EAAQC","file":"out.js"}
      MAP
    end
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
        source_map: {
          filename: "out.js"
        }
      }
    }

    it "remaps source_map" do
      expect(context).to receive(:call) do |function, code, passed_options|
        expect(passed_options[:sourceMap]).to eq(filename: "out.js")
      end

      described_class.minify(code, options)
    end
  end
end
