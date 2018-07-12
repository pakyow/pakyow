RSpec.describe "rendering ui components" do
  let :view do
    Pakyow::Presenter::View.new("<div ui=\"notifier\" config=\"message: hello\"></div>")
  end

  it "includes data-ui" do
    expect(view.to_s).to include("data-ui=\"notifier\"")
  end

  it "includes data-config" do
    expect(view.to_s).to include("data-config=\"message: hello\"")
  end
end
