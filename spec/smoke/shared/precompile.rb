RSpec.shared_examples "precompile" do
  before do
    # Create an asset.
    #
    project_path.join("frontend/assets/application.scss").open("w+") do |file|
      file.write <<~SOURCE
        body {
          font-family: Helvetica;
        }
      SOURCE
    end
  end

  it "precompiles scss" do
    expect(Dir.glob(project_path.join("public/**/*"))).to include(
      project_path.join("public/assets/application__4403ff822a9a0e68b040f90c9210427a.css").to_s
    )

    expect(project_path.join("public/assets/application__4403ff822a9a0e68b040f90c9210427a.css").read).to eq(
      "body{font-family:Helvetica}\n\n/*# sourceMappingURL=/assets/application__4403ff822a9a0e68b040f90c9210427a.css.map */\n"
    )
  end

  it "precompiles scss source maps" do
    expect(Dir.glob(project_path.join("public/**/*"))).to include(
      project_path.join("public/assets/application__4403ff822a9a0e68b040f90c9210427a.css.map").to_s
    )

    expect(project_path.join("public/assets/application__4403ff822a9a0e68b040f90c9210427a.css.map").read).to eq(
      "{\"version\":3,\"file\":\"application__4403ff822a9a0e68b040f90c9210427a.css\",\"sourceRoot\":\"/\",\"sources\":[\"/frontend/assets/application.scss\"],\"names\":[],\"mappings\":\"AAAA,AAAA,IAAI,AAAC,CACH,WAAW,CAAE,SAAS,CACvB\",\"sourcesContent\":[\"body {\\n  font-family: Helvetica;\\n}\\n\"]}"
    )
  end
end
