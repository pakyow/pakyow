RSpec.describe "setting attributes via presenter" do
  include_context "app"

  let :presenter do
    Pakyow::Presenter::Presenter.new(view, app: Pakyow.apps[0])
  end

  context "string attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" title=\"foo\"></div>").find(:post)
      end

      it "can be overridden" do
        presenter.attributes[:title] = "bar"
        expect(presenter.to_html).to include("title=\"bar\"")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "can be set" do
        presenter.attributes[:title] = "bar"
        expect(presenter.to_html).to include("title=\"bar\"")
      end
    end

    context "when the value is not a string" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "is typecast to a string" do
        presenter.attributes[:title] = true
        expect(presenter.to_html).to include("title=\"true\"")
      end
    end
  end

  context "hash attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" style=\"color: red;\"></div>").find(:post)
      end

      it "can be overridden" do
        presenter.attributes[:style] = { color: "blue" }
        expect(presenter.to_html).to include("style=\"color: blue;\"")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "can be set" do
        presenter.attributes[:style] = { color: "blue" }
        expect(presenter.to_html).to include("style=\"color: blue;\"")
      end
    end

    context "when the value is a string" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "converts the string into a hash" do
        presenter.attributes[:style] = "color: blue; text-decoration: underline"
        expect(presenter.to_html).to include("style=\"color: blue; text-decoration: underline;\"")
      end

      context "when the value cannot be converted" do
        it "does the best it can" do
          presenter.attributes[:style] = "tnyfua;awt-"
          expect(presenter.to_html).to include("style=\"\"")
        end
      end
    end

    context "when the value is not a hash or string" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "typecasts value to a string and converts it" do
        presenter.attributes[:style] = []
        expect(presenter.to_html).to include("style=\"\"")
      end
    end
  end

  context "set attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" class=\"foo bar\"></div>").find(:post)
      end

      it "can be overridden" do
        presenter.attributes[:class] = :foo
        expect(presenter.to_html).to include("class=\"foo\"")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "can be set" do
        presenter.attributes[:class] = :foo
        expect(presenter.to_html).to include("class=\"foo\"")
      end
    end

    context "when the value is an array" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "is typecast to a set" do
        presenter.attributes[:class] = [:foo, "bar"]
        expect(presenter.to_html).to include("class=\"foo bar\"")
      end
    end

    context "when the value is an string" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "converts the value into a set" do
        presenter.attributes[:class] = "foo bar"
        expect(presenter.to_html).to include("class=\"foo bar\"")
      end

      context "when the value cannot be converted" do
        it "does the best it can" do
          presenter.attributes[:class] = "foo;bar"
          expect(presenter.to_html).to include("class=\"foo;bar\"")
        end
      end
    end

    context "when the value is not a set, array, or string" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "typecasts value to a string and converts it" do
        presenter.attributes[:class] = {}
        expect(presenter.to_html).to include("class=\"{}\"")
      end
    end
  end

  context "boolean attributes" do
    context "when the attribute exists in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\" checked=\"checked\"></div>").find(:post)
      end

      it "can be overridden" do
        presenter.attributes[:checked] = true
        expect(presenter.to_html).to include("checked=\"checked\"")
      end
    end

    context "when the attribute does not exist in the view" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"></div>").find(:post)
      end

      it "can be set" do
        presenter.attributes[:checked] = true
        expect(presenter.to_html).to include("checked=\"checked\"")
      end
    end
  end
end
