RSpec.describe "presenter helpers" do
  include_examples "testable app"

  it "registers Presenter::Helpers::Exposures as an active helper" do
    expect(app.helpers(:active)).to include(Pakyow::Presenter::Helpers::Exposures)
  end

  it "registers Presenter::Helpers::Rendering as an active helper" do
    expect(app.helpers(:active)).to include(Pakyow::Presenter::Helpers::Rendering)
  end

  it "includes global helpers into Binder" do
    app.helpers(:global).reject { |helper| helper.name.nil? }.each do |helper|
      expect(app.isolated(:Binder).ancestors).to include(helper)
    end
  end

  it "includes global helpers into Presenter" do
    app.helpers(:global).reject { |helper| helper.name.nil? }.each do |helper|
      expect(app.isolated(:Presenter).ancestors).to include(helper)
    end
  end

  it "includes active helpers into Component" do
    app.helpers(:active).reject { |helper| helper.name.nil? }.each do |helper|
      expect(app.isolated(:Component).ancestors).to include(helper)
    end
  end

  it "includes passive helpers into ComponentRenderer" do
    app.helpers(:passive).reject { |helper| helper.name.nil? }.each do |helper|
      expect(app.isolated(:ComponentRenderer).ancestors).to include(helper)
    end
  end

  it "includes passive helpers into ViewRenderer" do
    app.helpers(:passive).reject { |helper| helper.name.nil? }.each do |helper|
      expect(app.isolated(:ViewRenderer).ancestors).to include(helper)
    end
  end
end
