RSpec.describe "embedding source mapping url" do
  include_context "app"

  let :app_def do
    local = self

    Proc.new do
      config.assets.process = true
      config.assets.source_maps = local.source_maps
    end
  end

  let :source_maps do
    true
  end

  describe "requesting a css stylesheet" do
    it "adds the source mapping url to the asset content" do
      expect(call("/assets/default.css")[2]).to include("\n/*# sourceMappingURL=/assets/default.css.map */\n")
    end

    context "source maps are disabled" do
      let :source_maps do
        false
      end

      it "does not add the source mapping url to the asset content" do
        expect(call("/assets/default.css")[2]).to_not include("/*# sourceMappingURL\n")
      end
    end
  end

  describe "requesting a sass stylesheet" do
    it "adds the source mapping url to the asset content" do
      expect(call("/assets/types-sass.css")[2]).to include("\n/*# sourceMappingURL=/assets/types-sass.css.map */\n")
    end

    context "source maps are disabled" do
      let :source_maps do
        false
      end

      it "does not add the source mapping url to the asset content" do
        expect(call("/assets/types-sass.css")[2]).to_not include("/*# sourceMappingURL\n")
      end
    end
  end

  describe "requesting a javascript" do
    it "adds the source mapping url to the asset content" do
      expect(call("/assets/types-js.js")[2]).to include("\n//# sourceMappingURL=/assets/types-js.js.map\n")
    end

    context "source maps are disabled" do
      let :source_maps do
        false
      end

      it "does not add the source mapping url to the asset content" do
        expect(call("/assets/types-js.js")[2]).to_not include("\n/*# sourceMappingURL\n")
      end
    end
  end

  describe "requesting a javascript pack" do
    it "adds the source mapping url to the asset content" do
      expect(call("/assets/packs/pages/source_mapped.js")[2]).to include("\n//# sourceMappingURL=/assets/packs/pages/source_mapped.js.map\n")
    end

    context "source maps are disabled" do
      let :source_maps do
        false
      end

      it "does not add the source mapping url to the asset content" do
        expect(call("/assets/packs/pages/source_mapped.js")[2]).not_to include("/*# sourceMappingURL=")
      end
    end
  end

  describe "requesting a css pack that has a source map" do
    before do
      require "sassc"
    end

    it "adds the source mapping url to the asset content" do
      expect(call("/assets/packs/pages/source_mapped.css")[2]).to include("/*# sourceMappingURL=/assets/packs/pages/source_mapped.css.map */\n")
    end

    context "source maps are disabled" do
      let :source_maps do
        false
      end

      it "does not add the source mapping url to the asset content" do
        expect(call("/assets/packs/pages/source_mapped.css")[2]).not_to include("/*# sourceMappingURL=")
      end
    end
  end
end

RSpec.describe "serving source maps from the processor" do
  include_context "app"

  let :app_def do
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

  context "asset is a javascript" do
    it "responds to the source map request" do
      expect(call("/assets/types-js.js.map")[0]).to eq(200)
    end

    it "responds with the expected source map" do
      map = JSON.parse(call("/assets/types-js.js.map")[2])

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("types-js.js")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/spec/support/app/frontend/assets/types-js.js"
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
        map = JSON.parse(call("/assets/types-js.js.map")[2])

        expect(map["version"]).to eq(3)
        expect(map["file"]).to eq("types-js.js")
        expect(map["sourceRoot"]).to eq("/")

        expect(map["sources"]).to eq([
          "/spec/support/app/frontend/assets/types-js.js"
        ])

        expect(map["names"]).to eq(
          ["Rectangle", "foo", "_classCallCheck", "this", "console", "log"]
        )

        expect(map["mappings"]).to eq(
          "mQAAMA,UACJ,SAAAA,UAAYC,GAAKC,gBAAAC,KAAAH,WACfI,QAAQC,IAAIJ"
        )

        expect(map["sourcesContent"]).to eq([
          File.read(File.join(Pakyow.apps.first.config.assets.path, "types-js.js"))
        ])
      end
    end
  end

  context "asset is a stylesheet" do
    it "responds to the source map request" do
      expect(call("/assets/types-sass.css.map")[0]).to eq(200)
    end

    it "responds with the expected source map" do
      map = JSON.parse(call("/assets/types-sass.css.map")[2])

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("types-sass.css")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/spec/support/app/frontend/assets/types-sass.sass"
      ])

      expect(map["names"]).to eq(
        []
      )

      expect(map["mappings"]).to eq(
        "AAAA,AAAA,IAAI,CAAC;EACH,UAAU,EAAU,OAAG,GAAS"
      )

      expect(map["sourcesContent"]).to eq([
        "body {\n  background: lighten(red, 10%); }\n"
      ])
    end
  end

  context "asset is a stylesheet with dependencies" do
    it "responds to the source map request" do
      expect(call("/assets/types-sass-with-deps.css.map")[0]).to eq(200)
    end

    it "responds with the expected source map" do
      map = JSON.parse(call("/assets/types-sass-with-deps.css.map")[2])

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("types-sass-with-deps.css")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/spec/support/app/frontend/assets/types-sass-with-deps.sass",
        "/spec/support/app/frontend/assets/_deps.sass"
      ])

      expect(map["names"]).to eq(
        []
      )

      expect(map["mappings"]).to eq(
        "AAEA,AAAA,IAAI,CAAC;EACH,UAAU,ECHE,OAAG,GDGI"
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
      map = JSON.parse(call("/assets/packs/pages/source_mapped.js.map")[2])

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("source_mapped.js")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/spec/support/app/frontend/pages/source_mapped/_partial.js",
        "/spec/support/app/frontend/pages/source_mapped/index.js"
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
        map = JSON.parse(call("/assets/packs/pages/source_mapped.js.map")[2])

        expect(map["version"]).to eq(3)
        expect(map["file"]).to eq("source_mapped.js")
        expect(map["sourceRoot"]).to eq("/")

        expect(map["sources"]).to eq([
          "/spec/support/app/frontend/pages/source_mapped/_partial.js",
          "/spec/support/app/frontend/pages/source_mapped/index.js"
        ])

        expect(map["names"]).to eq(
          ["Bar", "Foo", "bar", "foo", "_classCallCheck", "this", "console", "log"]
        )

        expected_mappings = [{:generated_line=>1,
                              :generated_col=>259,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/index.js",
                              :source_line=>1,
                              :source_col=>6,
                              :name=>"Foo"},
                             {:generated_line=>1,
                              :generated_col=>259,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.js",
                              :source_line=>1,
                              :source_col=>6,
                              :name=>"Bar"},
                             {:generated_line=>1,
                              :generated_col=>263,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.js",
                              :source_line=>2,
                              :source_col=>2},
                             {:generated_line=>1,
                              :generated_col=>263,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/index.js",
                              :source_line=>2,
                              :source_col=>2},
                             {:generated_line=>1,
                              :generated_col=>272,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/index.js",
                              :source_line=>2,
                              :source_col=>2,
                              :name=>"Foo"},
                             {:generated_line=>1,
                              :generated_col=>272,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.js",
                              :source_line=>2,
                              :source_col=>2,
                              :name=>"Bar"},
                             {:generated_line=>1,
                              :generated_col=>276,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.js",
                              :source_line=>2,
                              :source_col=>14,
                              :name=>"bar"},
                             {:generated_line=>1,
                              :generated_col=>276,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/index.js",
                              :source_line=>2,
                              :source_col=>14,
                              :name=>"foo"},
                             {:generated_line=>1,
                              :generated_col=>279,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/index.js",
                              :source_line=>2,
                              :source_col=>19,
                              :name=>"_classCallCheck"},
                             {:generated_line=>1,
                              :generated_col=>279,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.js",
                              :source_line=>2,
                              :source_col=>19,
                              :name=>"_classCallCheck"},
                             {:generated_line=>1,
                              :generated_col=>295,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/index.js",
                              :source_line=>2,
                              :source_col=>19,
                              :name=>"this"},
                             {:generated_line=>1,
                              :generated_col=>295,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.js",
                              :source_line=>2,
                              :source_col=>19,
                              :name=>"this"},
                             {:generated_line=>1,
                              :generated_col=>300,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/index.js",
                              :source_line=>2,
                              :source_col=>19,
                              :name=>"Foo"},
                             {:generated_line=>1,
                              :generated_col=>300,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.js",
                              :source_line=>2,
                              :source_col=>19,
                              :name=>"Bar"},
                             {:generated_line=>1,
                              :generated_col=>305,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.js",
                              :source_line=>3,
                              :source_col=>4,
                              :name=>"console"},
                             {:generated_line=>1,
                              :generated_col=>305,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/index.js",
                              :source_line=>3,
                              :source_col=>4,
                              :name=>"console"},
                             {:generated_line=>1,
                              :generated_col=>313,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.js",
                              :source_line=>3,
                              :source_col=>12,
                              :name=>"log"},
                             {:generated_line=>1,
                              :generated_col=>313,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/index.js",
                              :source_line=>3,
                              :source_col=>12,
                              :name=>"log"},
                             {:generated_line=>1,
                              :generated_col=>317,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.js",
                              :source_line=>3,
                              :source_col=>16,
                              :name=>"bar"},
                             {:generated_line=>1,
                              :generated_col=>317,
                              :source=>"/spec/support/app/frontend/pages/source_mapped/index.js",
                              :source_line=>3,
                              :source_col=>16,
                              :name=>"foo"}]

        mappings = SourceMap.from_json(map).mappings

        expect(mappings.count).to eq(expected_mappings.count)

        mappings.each do |mapping|
          expect(expected_mappings).to include(mapping)
        end

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
      map = JSON.parse(call("/assets/packs/pages/source_mapped.css.map")[2])

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("source_mapped.css")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/spec/support/app/frontend/pages/source_mapped/_partial.sass",
        "/spec/support/app/frontend/pages/source_mapped/index.sass"
      ])

      expect(map["names"]).to eq(
        []
      )

      expected_mappings = [{:generated_line=>1,
                            :generated_col=>0,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.sass",
                            :source_line=>1,
                            :source_col=>0},
                           {:generated_line=>1,
                            :generated_col=>0,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.sass",
                            :source_line=>1,
                            :source_col=>0},
                           {:generated_line=>1,
                            :generated_col=>0,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/index.sass",
                            :source_line=>1,
                            :source_col=>0},
                           {:generated_line=>1,
                            :generated_col=>0,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/index.sass",
                            :source_line=>1,
                            :source_col=>0},
                           {:generated_line=>1,
                            :generated_col=>4,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/index.sass",
                            :source_line=>1,
                            :source_col=>4},
                           {:generated_line=>1,
                            :generated_col=>4,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.sass",
                            :source_line=>1,
                            :source_col=>4},
                           {:generated_line=>1,
                            :generated_col=>5,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/index.sass",
                            :source_line=>1,
                            :source_col=>5},
                           {:generated_line=>1,
                            :generated_col=>5,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.sass",
                            :source_line=>1,
                            :source_col=>5},
                           {:generated_line=>2,
                            :generated_col=>2,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/index.sass",
                            :source_line=>2,
                            :source_col=>2},
                           {:generated_line=>2,
                            :generated_col=>2,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.sass",
                            :source_line=>2,
                            :source_col=>2},
                           {:generated_line=>2,
                            :generated_col=>12,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.sass",
                            :source_line=>2,
                            :source_col=>12},
                           {:generated_line=>2,
                            :generated_col=>12,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/index.sass",
                            :source_line=>2,
                            :source_col=>12},
                           {:generated_line=>2,
                            :generated_col=>14,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.sass",
                            :source_line=>2,
                            :source_col=>22},
                           {:generated_line=>2,
                            :generated_col=>14,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/index.sass",
                            :source_line=>2,
                            :source_col=>22},
                           {:generated_line=>2,
                            :generated_col=>21,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/index.sass",
                            :source_line=>2,
                            :source_col=>26},
                           {:generated_line=>2,
                            :generated_col=>21,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.sass",
                            :source_line=>2,
                            :source_col=>25},
                           {:generated_line=>2,
                            :generated_col=>24,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/_partial.sass",
                            :source_line=>2,
                            :source_col=>34},
                           {:generated_line=>2,
                            :generated_col=>24,
                            :source=>"/spec/support/app/frontend/pages/source_mapped/index.sass",
                            :source_line=>2,
                            :source_col=>35}]

      mappings = SourceMap.from_json(map).mappings

      expect(mappings.count).to eq(expected_mappings.count)

      mappings.each do |mapping|
        expect(expected_mappings).to include(mapping)
      end

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
      map = JSON.parse(call("/assets/packs/external-transpiled.js.map")[2])

      expect(map["version"]).to eq(3)
      expect(map["file"]).to eq("external-transpiled.js")
      expect(map["sourceRoot"]).to eq("/")

      expect(map["sources"]).to eq([
        "/spec/support/app/frontend/assets/packs/vendor/external-transpiled.js"
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
