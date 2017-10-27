RSpec.describe "setting string attributes" do
  context "when the attribute exists in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post title=\"foo\"></div>").find(:post)
    end

    it "can be overridden" do
      view.attributes[:title] = "bar"
      expect(view.to_html).to include("title=\"bar\"")
    end
  end

  context "when the attribute does not exist in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "can be set" do
      view.attributes[:title] = "bar"
      expect(view.to_html).to include("title=\"bar\"")
    end
  end

  context "when the value is not a string" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "is typecast to a string" do
      view.attributes[:title] = true
      expect(view.to_html).to include("title=\"true\"")
    end
  end
end

RSpec.describe "setting hash attributes" do
  context "when the attribute exists in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post style=\"color:red\"></div>").find(:post)
    end

    it "can be overridden" do
      view.attributes[:style] = { color: "blue" }
      expect(view.to_html).to include("style=\"color:blue\"")
    end
  end

  context "when the attribute does not exist in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "can be set" do
      view.attributes[:style] = { color: "blue" }
      expect(view.to_html).to include("style=\"color:blue\"")
    end
  end

  context "when the value is a string" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "converts the string into a hash" do
      view.attributes[:style] = "color: blue; text-decoration: underline"
      expect(view.to_html).to include("style=\"color:blue;text-decoration:underline\"")
    end

    context "when the value cannot be converted" do
      it "does the best it can" do
        view.attributes[:style] = "tnyfua;awt-"
        expect(view.to_html).to include("style=\"\"")
      end
    end
  end

  context "when the value is not a hash or string" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "typecasts value to a string and converts it" do
      view.attributes[:style] = []
      expect(view.to_html).to include("style=\"\"")
    end
  end
end

RSpec.describe "setting set attributes" do
  context "when the attribute exists in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post class=\"foo bar\"></div>").find(:post)
    end

    it "can be overridden" do
      view.attributes[:class] = :foo
      expect(view.to_html).to include("class=\"foo\"")
    end
  end

  context "when the attribute does not exist in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "can be set" do
      view.attributes[:class] = :foo
      expect(view.to_html).to include("class=\"foo\"")
    end
  end

  context "when the value is an array" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "is typecast to a set" do
      view.attributes[:class] = [:foo, "bar"]
      expect(view.to_html).to include("class=\"foo bar\"")
    end
  end

  context "when the value is an string" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "converts the value into a set" do
      view.attributes[:class] = "foo bar"
      expect(view.to_html).to include("class=\"foo bar\"")
    end

    context "when the value cannot be converted" do
      it "does the best it can" do
        view.attributes[:class] = "foo;bar"
        expect(view.to_html).to include("class=\"foo;bar\"")
      end
    end
  end

  context "when the value is not a set, array, or string" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "typecasts value to a string and converts it" do
      view.attributes[:class] = {}
      expect(view.to_html).to include("class=\"{}\"")
    end
  end
end

RSpec.describe "setting boolean attributes" do
  context "when the attribute exists in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post checked=\"checked\"></div>").find(:post)
    end

    it "can be overridden" do
      view.attributes[:checked] = true
      expect(view.to_html).to include("checked=\"checked\"")
    end
  end

  context "when the attribute does not exist in the view" do
    let :view do
      Pakyow::Presenter::View.new("<div@post></div>").find(:post)
    end

    it "can be set" do
      view.attributes[:checked] = true
      expect(view.to_html).to include("checked=\"checked\"")
    end
  end
end
