RSpec.describe "embedding source mapping url" do
  include_context "app"

  let :app_init do
    local = self

    Proc.new do
      config.assets.process = true
      config.assets.source_maps = local.source_maps
    end
  end

  let :source_maps do
    true
  end

  describe "requesting a stylesheet with a source map" do
    it "adds the source mapping url to the asset content" do
      expect(call("/types-sass.css")[2].body.read).to include("\n/*# sourceMappingURL=/types-sass.css.map */\n")
    end

    context "source maps are disabled" do
      let :source_maps do
        false
      end

      it "does not add the source mapping url to the asset content" do
        expect(call("/types-sass.css")[2].body.read).to_not include("/*# sourceMappingURL\n")
      end
    end
  end

  describe "requesting a javascript" do
    it "adds the source mapping url to the asset content" do
      expect(call("/types-js.js")[2].body.read).to include("\n//# sourceMappingURL=/types-js.js.map\n")
    end

    context "source maps are disabled" do
      let :source_maps do
        false
      end

      it "does not add the source mapping url to the asset content" do
        expect(call("/types-js.js")[2].body.read).to_not include("\n/*# sourceMappingURL\n")
      end
    end
  end

  describe "requesting a javascript pack" do
    it "adds the source mapping url to the asset content" do
      expect(call("/assets/packs/pages/source_mapped.js")[2].body.read).to include("\n//# sourceMappingURL=/assets/packs/pages/source_mapped.js.map\n")
    end

    context "source maps are disabled" do
      let :source_maps do
        false
      end

      it "does not add the source mapping url to the asset content" do
        expect(call("/assets/packs/pages/source_mapped.js")[2].body.read).not_to include("/*# sourceMappingURL=")
      end
    end
  end

  describe "requesting a css pack that has a source map" do
    before do
      require "sassc"
    end

    it "adds the source mapping url to the asset content" do
      expect(call("/assets/packs/pages/source_mapped.css")[2].body.read).to include("/*# sourceMappingURL=/assets/packs/pages/source_mapped.css.map */\n")
    end

    context "source maps are disabled" do
      let :source_maps do
        false
      end

      it "does not add the source mapping url to the asset content" do
        expect(call("/assets/packs/pages/source_mapped.css")[2].body.read).not_to include("/*# sourceMappingURL=")
      end
    end
  end
end

RSpec.describe "serving source maps from the processor" do
  include_context "app"

  let :app_init do
    local = self
    Proc.new do
      config.assets.process = true
      config.assets.source_maps = true
      config.assets.minify = local.minify
    end
  end

  let :minify do
    false
  end

  let :relative_path do
    Pathname.new(File.expand_path("../../", __FILE__)).relative_path_from(Pathname.new(Dir.pwd)).to_s
  end

  context "asset is a javascript" do
    it "responds to the source map request" do
      expect(call("/types-js.js.map")[0]).to eq(200)
    end

    it "responds with the expected source map" do
      map = JSON.parse(call("/types-js.js.map")[2].body.read)

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("types-js.js")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/#{relative_path}/support/app/frontend/assets/types-js.js"
      ])

      expect(map["names"]).to eq(
        ["Rectangle","foo","console","log"]
      )

      expect(map["mappings"]).to eq(
        ";;;;;;IAAMA,S,GACJ,mBAAYC,GAAZ,EAAiB;AAAA;;AACfC,EAAAA,OAAO,CAACC,GAAR,CAAYF,GAAZ;AACD,C"
      )

      expect(map["sourcesContent"]).to eq([
        File.read(File.join(Pakyow.apps.first.config.assets.path, "types-js.js"))
      ])
    end

    context "asset is minified" do
      let :minify do
        true
      end

      it "responds with the expected source map" do
        map = JSON.parse(call("/types-js.js.map")[2].body.read)

        expect(map["version"]).to eq(3)
        expect(map["file"]).to eq("types-js.js")
        expect(map["sourceRoot"]).to eq("/")

        expect(map["sources"]).to eq([
          "/#{relative_path}/support/app/frontend/assets/types-js.js"
        ])

        expect(map["names"]).to eq(
          ["Rectangle", "foo", "_classCallCheck", "this", "console", "log"]
        )

        expect(map["mappings"]).to eq(
          "iQAAMA,UACJ,SAAAA,UAAYC,GAAKC,gBAAAC,KAAAH,WACfI,QAAQC,IAAIJ"
        )

        expect(map["sourcesContent"]).to eq([
          File.read(File.join(Pakyow.apps.first.config.assets.path, "types-js.js"))
        ])
      end
    end
  end

  context "asset is a stylesheet" do
    it "responds to the source map request" do
      expect(call("/types-sass.css.map")[0]).to eq(200)
    end

    it "responds with the expected source map" do
      map = JSON.parse(call("/types-sass.css.map")[2].body.read)

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("types-sass.css")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/#{relative_path}/support/app/frontend/assets/types-sass.sass"
      ])

      expect(map["names"]).to eq(
        []
      )

      expect(map["mappings"]).to eq(
        "AAAA,AAAA,IAAI,CAAC;EACH,UAAU,EAAE,OAAiB,GAAG"
      )

      expect(map["sourcesContent"]).to eq([
        "body {\n  background: lighten(red, 10%); }\n"
      ])
    end
  end

  context "asset is a stylesheet with dependencies" do
    it "responds to the source map request" do
      expect(call("/types-sass-with-deps.css.map")[0]).to eq(200)
    end

    it "responds with the expected source map" do
      map = JSON.parse(call("/types-sass-with-deps.css.map")[2].body.read)

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("types-sass-with-deps.css")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/#{relative_path}/support/app/frontend/assets/types-sass-with-deps.sass",
        "/#{relative_path}/support/app/frontend/assets/_deps.sass"
      ])

      expect(map["names"]).to eq(
        []
      )

      expect(map["mappings"]).to eq(
        "AAEA,AAAA,IAAI,CAAC;EACH,UAAU,ECHN,OAAiB,GDGF"
      )

      expect(map["sourcesContent"]).to eq([
        "@import \"deps\";\n\nbody {\n  background: $red; }\n",
        "$red: lighten(red, 10%);\n"
      ])
    end
  end

  context "asset is a js pack" do
    it "responds to the source map request" do
      expect(call("/assets/packs/pages/source_mapped.js.map")[0]).to eq(200)
    end

    it "responds with the expected source map" do
      map = JSON.parse(call("/assets/packs/pages/source_mapped.js.map")[2].body.read)

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("source_mapped.js")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/#{relative_path}/support/app/frontend/pages/source_mapped/_partial.js",
        "/#{relative_path}/support/app/frontend/pages/source_mapped/index.js"
      ])

      expect(map["names"]).to eq(
        ["Bar","Foo","bar","foo","console","log"]
      )

      expect(map["mappings"]).to eq(
        ";;;;;;IAAMA,ACAAC,G,A,GDCJ,ACAA,aDAYC,ACAAC,GDAZ,ACAA,EDAiB,ACAA;ADAA,ACAA;;ADCfC,ACAAA,EDAAA,ACAAA,ODAO,ACAA,CDACC,ACAAA,GDAR,ACAA,CDAYH,ACAAC,GDAZ,ACAA;ADCD,ACAA,C,A"
      )

      expect(map["sourcesContent"]).to eq([
        "class Bar {\n  constructor(bar) {\n    console.log(bar);\n  }\n}\n",
        "class Foo {\n  constructor(foo) {\n    console.log(foo);\n  }\n}\n"
      ])
    end

    context "asset is minified" do
      let :minify do
        true
      end

      it "responds with the expected source map" do
        map = JSON.parse(call("/assets/packs/pages/source_mapped.js.map")[2].body.read)

        expect(map["version"]).to eq(3)
        expect(map["file"]).to eq("source_mapped.js")
        expect(map["sourceRoot"]).to eq("/")

        expect(map["sources"]).to eq([
          "/#{relative_path}/support/app/frontend/pages/source_mapped/_partial.js",
          "/#{relative_path}/support/app/frontend/pages/source_mapped/index.js"
        ])

        expect(map["names"]).to eq(
          ["Bar", "Foo", "bar", "foo", "_classCallCheck", "this", "console", "log"]
        )

        expect(map["mappings"]).to eq(
          "iQAAMA,ACAAC,IDCJ,ACAA,SDAAD,ACAAC,IDAYC,ACAAC,GAAKC,ADAAA,gBCAAC,ADAAA,KCAAJ,ADAAD,KACfM,ACAAA,QDAQC,ACAAA,IDAIL,ACAAC"
        )

        expect(map["sourcesContent"]).to eq([
          "class Bar {\n  constructor(bar) {\n    console.log(bar);\n  }\n}\n",
          "class Foo {\n  constructor(foo) {\n    console.log(foo);\n  }\n}\n"
        ])
      end
    end
  end

  context "asset is a css pack" do
    it "responds to the source map request" do
      expect(call("/assets/packs/pages/source_mapped.css.map")[0]).to eq(200)
    end

    it "responds with the expected source map" do
      map = JSON.parse(call("/assets/packs/pages/source_mapped.css.map")[2].body.read)

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("source_mapped.css")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/#{relative_path}/support/app/frontend/pages/source_mapped/_partial.sass",
        "/#{relative_path}/support/app/frontend/pages/source_mapped/index.sass"
      ])

      expect(map["names"]).to eq(
        []
      )

      expect(map["mappings"]).to eq(
        "AAAA,AAAA,ACAA,AAAA,IAAI,ADAA,CCAC,ADAA;EACH,ACAA,UDAU,ACAA,EDAE,ACAA,OAAkB,ADAD,GAAG,ACAC"
      )

      expect(map["sourcesContent"]).to eq([
        "body {\n  background: lighten(red, 10%); }\n",
        "html {\n  background: lighten(blue, 10%); }\n"
      ])
    end
  end

  context "asset is a minified external js pack" do
    let :minify do
      true
    end

    it "responds with the expected source map" do
      map = JSON.parse(call("/assets/packs/external-transpiled.js.map")[2].body.read)

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("external-transpiled.js")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/#{relative_path}/support/app/frontend/assets/packs/vendor/external-transpiled.js"
      ])

      expect(map["names"]).to eq(
        ["_instanceof", "left", "right", "Symbol", "hasInstance", "_classCallCheck", "instance", "Constructor", "TypeError", "Rectangle", "foo", "this", "console", "log"]
      )

      expect(map["mappings"]).to eq(
        "AAAA,aAEA,SAASA,YAAYC,EAAMC,GAAS,OAAa,MAATA,GAAmC,oBAAXC,QAA0BD,EAAMC,OAAOC,aAAuBF,EAAMC,OAAOC,aAAaH,GAAuBA,aAAgBC,EAE/L,SAASG,gBAAgBC,EAAUC,GAAe,IAAKP,YAAYM,EAAUC,GAAgB,MAAM,IAAIC,UAAU,qCAEjH,IAAIC,UAAY,SAASA,UAAUC,GACjCL,gBAAgBM,KAAMF,WAEtBG,QAAQC,IAAIH"
      )

      expect(map["sourcesContent"]).to eq([
        File.read(File.join(Pakyow.apps.first.config.assets.path, "packs/vendor/external-transpiled.js"))
      ])
    end
  end
end
