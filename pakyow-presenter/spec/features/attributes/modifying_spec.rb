RSpec.describe "modifying attributes via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  context "string attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" title=\"foo\"></div>").find(:post)
      end

      it "can be modified" do
        presenter.attributes[:title].reverse!
        expect(presenter.to_html).to include("title=\"oof\"")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>")
      end

      it "cannot be modified" do
        expect {
          presenter.attributes[:title].reverse!
        }.to raise_error(NoMethodError)
      end
    end
  end

  context "hash attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" style=\"color:red\"></div>").find(:post)
      end

      it "can be modified" do
        presenter.attributes[:style][:color] = "blue"
        expect(presenter.to_html).to include("style=\"color:blue\"")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "cannot be modified" do
        expect {
          presenter.attributes[:style][:color] = "blue"
        }.to raise_error(NoMethodError)
      end
    end
  end

  context "set attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" class=\"foo bar\"></div>").find(:post)
      end

      it "can be modified" do
        presenter.attributes[:class].delete(:bar)
        expect(presenter.to_html).to include("class=\"foo\"")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "cannot be modified" do
        expect {
          presenter.attributes[:class].delete(:bar)
        }.to raise_error(NoMethodError)
      end
    end
  end
end
