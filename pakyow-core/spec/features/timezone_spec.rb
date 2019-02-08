RSpec.describe "setting the default timezone" do
  before do
    local = self
    Pakyow.configure do
      if tz = local.timezone
        config.timezone = tz
      end
    end
  end

  let :timezone do
    nil
  end

  include_context "app"

  it "sets the timezone to the default timezone" do
    expect(Time.now.zone).to eq("UTC")
  end

  context "timezone is changed" do
    let :timezone do
      "America/New_York"
    end

    it "sets the timezone to the configured timezone" do
      expect(Time.now.zone).to eq("EST")
    end
  end
end
