RSpec.describe "rendering ui components" do
  let :view do
    Pakyow::Presenter::View.new("<div ui=\"notifier(message: hello)\"></div>")
  end

  it "includes data-ui" do
    expect(view.to_s).to include("data-ui=\"notifier(message: hello)\"")
  end
end
