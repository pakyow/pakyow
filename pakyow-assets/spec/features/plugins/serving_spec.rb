require "pakyow/plugin"

RSpec.describe "serving assets from a plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable
      plug :testable, at: "/foo", as: :foo
    end
  end

  it "serves plugin assets at the default mount path" do
    expect(call("/assets/plugin.css")[0]).to eq(200)
  end

  it "serves plugin assets at a specific mount path" do
    expect(call("/assets/foo/plugin.css")[0]).to eq(200)
  end

  it "serves plugin packs at the default mount path" do
    expect(call("/assets/packs/plugin-pack.js")[0]).to eq(200)
  end

  it "serves plugin packs at a specific mount path" do
    expect(call("/assets/foo/packs/plugin-pack.js")[0]).to eq(200)
  end

  it "serves plugin public files at the default mount path" do
    expect(call("/plugin-favicon.ico")[0]).to eq(200)
  end

  it "serves plugin public files at a specific mount path" do
    expect(call("/foo/plugin-favicon.ico")[0]).to eq(200)
  end
end
