RSpec.describe "component helpers" do
  include_examples "testable app"

  it "includes known helpers into the app component class" do
    app.config.helpers.each do |helper|
      expect(app.isolated(:Component).ancestors).to include(helper)
    end
  end

  it "includes exposure helpers" do
    expect(app.isolated(:Component).ancestors).to include(Pakyow::Routing::Helpers::Exposures)
    expect(app.isolated(:Component).ancestors).to include(Pakyow::Presenter::Helpers::Exposures)
  end
end
