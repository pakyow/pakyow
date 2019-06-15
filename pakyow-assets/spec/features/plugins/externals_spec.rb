require "pakyow/plugin"

RSpec.describe "fetching externals defined in a plugin" do
  before do
    allow_any_instance_of(TTY::Spinner).to receive(:auto_spin)
    allow_any_instance_of(TTY::Spinner).to receive(:success)
    allow(FileUtils).to receive(:touch).and_call_original
  end

  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      after "configure" do
        external_script :jquery, "3.3.1"
      end
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "app"

  let :tmp do
    File.expand_path("../tmp", __FILE__)
  end

  after do
    if File.exist?(tmp)
      FileUtils.rm_r(tmp)
    end
  end

  let :app_def do
    local = self
    Proc.new do
      plug :testable

      configure :test do
        config.root = File.join(__dir__, "support/app")
        config.presenter.path = File.join(local.tmp, "frontend")
        config.assets.externals.fetch = true
        config.assets.externals.pakyow = false
        config.assets.externals.scripts = []
      end
    end
  end

  it "downloads into the app's assets directory" do
    expect(File.exist?(File.join(tmp, "frontend/assets/packs/vendor", "jquery@3.3.1.js"))).to be(true)
  end
end
