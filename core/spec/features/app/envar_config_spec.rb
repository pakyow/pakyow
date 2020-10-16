RSpec.describe "configuring an application with environment variables" do
  before do
    ENV["PWAPP__TEST__NAME"] = "env test"
  end

  after do
    ENV.delete("PWAPP__TEST__NAME")
  end

  include_context "app"

  it "configures" do
    expect(Pakyow.apps.first.config.name).to eq("env test")
  end
end
