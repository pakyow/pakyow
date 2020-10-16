RSpec.describe "configuring the environment with environment variables" do
  before do
    ENV["PWENV__DEFAULT_ENV"] = "test"
  end

  after do
    ENV.delete("PWENV__DEFAULT_ENV")
  end

  it "configures" do
    expect(Pakyow.config.default_env).to eq("test")
  end
end
