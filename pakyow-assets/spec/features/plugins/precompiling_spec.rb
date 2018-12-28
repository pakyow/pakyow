require "pakyow/plugin"

RSpec.describe "precompiling assets from a plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "app"

  let :app_definition do
    Proc.new {
      instance_exec(&$assets_app_boilerplate)

      plug :testable
      plug :testable, at: "/foo", as: :foo
    }
  end

  let :running_app do
    Pakyow.apps.first
  end

  before do
    require "pakyow/assets/precompiler"
    Pakyow::Assets::Precompiler.new(running_app).precompile!
  end

  after do
    FileUtils.rm_r(
      File.join(
        running_app.config.assets.compile_path,
        running_app.config.assets.prefix
      )
    )

    # Put back the assets that are needed for other tests.
    #
    FileUtils.mkdir_p(
      File.join(
        running_app.config.assets.compile_path,
        running_app.config.assets.prefix,
        "cache"
      )
    )
    FileUtils.touch(
      File.join(
        running_app.config.assets.compile_path,
        running_app.config.assets.prefix,
        "cache/default.css"
      )
    )
    FileUtils.mkdir_p(
      File.join(
        running_app.config.assets.compile_path,
        running_app.config.assets.prefix,
        "packs"
      )
    )
    FileUtils.touch(
      File.join(
        running_app.config.assets.compile_path,
        running_app.config.assets.prefix,
        "packs/test.css"
      )
    )
  end

  it "compiles plugin assets at the default mount path" do
    expect(
      File.exist?(
        File.join(
          running_app.config.assets.compile_path,
          running_app.config.assets.prefix,
          "plugin.css"
        )
      )
    ).to be(true)
  end

  it "compiles plugin assets at a specific mount path" do
    expect(
      File.exist?(
        File.join(
          running_app.config.assets.compile_path,
          running_app.config.assets.prefix,
          "foo/plugin.css"
        )
      )
    ).to be(true)
  end

  it "compiles plugin packs at the default mount path" do
    expect(
      File.exist?(
        File.join(
          running_app.config.assets.compile_path,
          running_app.config.assets.prefix,
          "packs/plugin-pack.js"
        )
      )
    ).to be(true)
  end

  it "compiles plugin packs at a specific mount path" do
    expect(
      File.exist?(
        File.join(
          running_app.config.assets.compile_path,
          running_app.config.assets.prefix,
          "foo/packs/plugin-pack.js"
        )
      )
    ).to be(true)
  end
end
