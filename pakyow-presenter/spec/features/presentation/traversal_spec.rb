RSpec.describe "view traversal via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  describe "components" do
    let :view do
      Pakyow::Presenter::View.new("<div ui=\"foo\"></div><div ui=\"bar\"></div><div ui=\"foo\"></div>")
    end

    it "returns an array of matching components" do
      components = presenter.components(:foo)
      expect(components.count).to eq(2)
      expect(components[0].attrs[:"data-ui"]).to eq("foo")
      expect(components[1].attrs[:"data-ui"]).to eq("foo")
    end

    context "when there is no matching component" do
      it "returns an empty array" do
        components = presenter.components(:nonexistent)
        expect(components.count).to eq(0)
      end
    end
  end
end
