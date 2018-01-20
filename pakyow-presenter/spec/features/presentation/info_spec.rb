RSpec.describe "view info via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  describe "accessing a key" do
    let :view do
      Pakyow::Presenter::View.new("", info: { "foo" => "bar" })
    end

    context "value exists" do
      it "returns the value" do
        expect(presenter.info(:foo)).to eq("bar")
      end
    end

    context "value does not exist" do
      it "returns nil" do
        expect(presenter.info(:bar)).to eq(nil)
      end
    end
  end

  describe "accessing info" do
    context "view has front matter" do
      let :view do
        Pakyow::Presenter::View.new("", info: { "foo" => "bar" })
      end

      it "returns a hash of values" do
        expect(presenter.info).to eq({ "foo" => "bar" })
      end
    end

    context "view has no front matter" do
      let :view do
        Pakyow::Presenter::View.new("<div></div>")
      end

      it "returns an empty hash" do
        expect(presenter.info).to eq({})
      end
    end
  end
end
