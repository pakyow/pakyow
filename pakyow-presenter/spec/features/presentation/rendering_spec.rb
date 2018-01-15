RSpec.describe "rendering via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
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
      expect(presenter.to_html).to eq("<div></div>")
    end
  end
end
