RSpec.describe "rendering via presenter" do
  include_context "app"

  let :presenter do
    Pakyow::Presenter::Presenter.new(view, app: Pakyow.apps[0])
  end

  let :view do
    Pakyow::Presenter::View.new("<div></div>")
  end

  describe "to_html" do
    it "returns an html string" do
      expect(presenter.to_html).to eq("<div></div>")
    end
  end

  describe "to_s" do
    it "returns an html string" do
      expect(presenter.to_s).to eq("<div></div>")
    end
  end
end
