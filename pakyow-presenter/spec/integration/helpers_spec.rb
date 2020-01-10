RSpec.describe "presenter helpers" do
  include_context "app"

  it "registers Presenter::Helpers::Rendering as an active helper" do
    expect(app.helpers_for_context(:active)).to include(Pakyow::Application::Helpers::Presenter::Rendering)
  end

  it "includes global helpers into Binder" do
    app.helpers_for_context(:global).reject { |helper| helper.name.nil? }.each do |helper|
      expect(app.isolated(:Binder).ancestors).to include(helper)
    end
  end

  it "includes global helpers into Presenter" do
    app.helpers_for_context(:global).reject { |helper| helper.name.nil? }.each do |helper|
      expect(app.isolated(:Presenter).ancestors).to include(helper)
    end
  end

  it "includes active helpers into Component" do
    app.helpers_for_context(:active).reject { |helper| helper.name.nil? }.each do |helper|
      expect(app.isolated(:Component).ancestors).to include(helper)
    end
  end
end
