RSpec.describe "modifying string attributes" do
  context "when the attribute exists in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post title=\"foo\"></div>").find(:post)
    end

    it "can be modified" do
      view.attributes[:title].reverse!
      expect(view.to_html).to include("title=\"oof\"")
    end
  end

  context "when the attribute does not exist in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>")
    end

    it "cannot be modified" do
      expect {
        view.attributes[:title].reverse!
      }.to raise_error(NoMethodError)
    end
  end
end

RSpec.describe "modifying hash attributes" do
  context "when the attribute exists in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post style=\"color:red\"></div>").find(:post)
    end

    it "can be modified" do
      view.attributes[:style][:color] = "blue"
      expect(view.to_html).to include("style=\"color:blue\"")
    end
  end

  context "when the attribute does not exist in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "cannot be modified" do
      expect {
        view.attributes[:style][:color] = "blue"
      }.to raise_error(NoMethodError)
    end
  end
end

RSpec.describe "modifying set attributes" do
  context "when the attribute exists in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post class=\"foo bar\"></div>").find(:post)
    end

    it "can be modified" do
      view.attributes[:class].delete(:bar)
      expect(view.to_html).to include("class=\"foo\"")
    end
  end

  context "when the attribute does not exist in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "cannot be modified" do
      expect {
        view.attributes[:class].delete(:bar)
      }.to raise_error(NoMethodError)
    end
  end
end
