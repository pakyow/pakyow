RSpec.describe "routing helpers" do
  include_context "app"

  it "registers Routing::Helpers::Exposures as an active helper" do
    expect(app.helpers(:active)).to include(Pakyow::Routing::Helpers::Exposures)
  end

  it "includes active helpers into Controller" do
    app.helpers(:active).reject { |helper| helper.name.nil? }.each do |helper|
      expect(app.isolated(:Controller).ancestors).to include(helper)
    end
  end
end
