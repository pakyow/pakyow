RSpec.shared_examples :setting_view_attributes do
  let :html do
    "<div@post style=\"color: blue\" class=\"foo bar\" title=\"baz\" checked=\"checked\"></div>"
  end

  let :doc do
    Pakyow::Presenter::StringDoc.new(html)
  end

  let :view do
    Pakyow::Presenter::View.new(object: doc.nodes.first)
  end

  let :attributes do
    testable.attributes
  end

  context "when attribute is of type hash" do
    let :value do
      attributes[:style]
    end

    describe "replacing the entire value with a hash" do
      before do
        attributes[:style] = { color: "red" }
      end

      it "typecasts the value" do
        expect(value).to be_instance_of(Pakyow::Presenter::Attributes::Hash)
      end

      it "sets the entire value" do
        expect(value).to eq({ color: "red" })
      end

      it "includes the value in the rendered html" do
        expect(testable.to_html).to include("color:red")
      end
    end

    describe "replacing the entire value with a string" do
      before do
        attributes[:style] = "color: red"
      end

      it "typecasts the value" do
        expect(value).to be_instance_of(Pakyow::Presenter::Attributes::Hash)
      end

      it "sets the entire value" do
        expect(value).to eq({ color: "red" })
      end

      it "includes the value in the rendered html" do
        expect(testable.to_html).to include("color:red")
      end
    end

    describe "replacing one key in the value" do
      before do
        attributes[:style][:color] = "red"
      end

      it "sets the value" do
        expect(value[:color]).to eq("red")
      end

      it "includes the value in the rendered html" do
        expect(testable.to_html).to include("color:red")
      end
    end
  end

  context "when attribute is of type set" do
    let :value do
      attributes[:class]
    end

    describe "replacing the entire value with a set" do
      before do
        attributes[:class] = [:baz].to_set
      end

      it "typecasts the value" do
        expect(value).to be_instance_of(Pakyow::Presenter::Attributes::Set)
      end

      it "sets the entire value" do
        expect(value.to_a).to eq([:baz])
      end

      it "includes the value in the rendered html" do
        expect(testable.to_html).to include("class=\"baz\"")
      end
    end

    describe "replacing the entire value with an array" do
      before do
        attributes[:class] = [:baz]
      end

      it "typecasts the value" do
        expect(value).to be_instance_of(Pakyow::Presenter::Attributes::Set)
      end

      it "sets the entire value" do
        expect(value).to eq([:baz].to_set)
      end

      it "includes the value in the rendered html" do
        expect(testable.to_html).to include("class=\"baz\"")
      end
    end

    describe "replacing the entire value with a string" do
      before do
        attributes[:class] = "baz zab"
      end

      it "typecasts the value" do
        expect(value).to be_instance_of(Pakyow::Presenter::Attributes::Set)
      end

      it "sets the entire value" do
        expect(value).to eq([:baz, :zab].to_set)
      end

      it "includes the value in the rendered html" do
        expect(testable.to_html).to include("class=\"baz zab\"")
      end
    end

    describe "modifying the value" do
      before do
        attributes[:class] << :additional
      end

      it "sets the value" do
        expect(value.to_a).to eq([:foo, :bar, :additional])
      end

      it "includes the value in the rendered html" do
        expect(testable.to_html).to include("class=\"foo bar additional\"")
      end
    end
  end

  context "when attribute is of type boolean" do
    let :value do
      attributes[:selected]
    end

    describe "setting the value for a nonexistent attribute to true" do
      before do
        attributes[:selected] = true
      end

      it "sets the value" do
        expect(value).to be(true)
      end

      it "includes the value in the rendered html" do
        expect(testable.to_html).to include("selected=\"selected\"")
      end
    end

    describe "setting the value for an existing attribute to false" do
      before do
        attributes[:checked] = false
      end

      it "removes the value" do
        expect(value).to be(false)
      end

      it "does not include the value in the rendered html" do
        expect(testable.to_html).not_to include("checked")
      end
    end
  end

  context "when attribute is of type string" do
    let :value do
      attributes[:title]
    end

    describe "replacing the entire value with a string" do
      before do
        attributes[:title] = "newtitle"
      end

      it "typecasts the value" do
        expect(value).to be_instance_of(Pakyow::Presenter::Attributes::String)
      end

      it "sets the entire value" do
        expect(value).to eq("newtitle")
      end

      it "includes the value in the rendered html" do
        expect(testable.to_html).to include("title=\"newtitle\"")
      end
    end

    describe "modifying the value" do
      before do
        attributes[:title].reverse!
      end

      it "modifies the value" do
        expect(value).to eq("zab")
      end

      it "includes the value in the rendered html" do
        expect(testable.to_html).to include("title=\"zab\"")
      end
    end
  end
end

RSpec.describe "setting attributes on a view" do
  include_examples :setting_view_attributes

  let :testable do
    view
  end
end

RSpec.describe "setting attributes on a duped view" do
  include_examples :setting_view_attributes

  let :testable do
    view.dup
  end

  # TODO: setting boolean, set, string attributes

  describe "the original view object" do
    context "when modifying a hash attribute" do
      context "when replacing the entire value with a hash" do
        before do
          attributes[:style] = { color: "red" }
        end

        it "is not modified" do
          expect(view.to_html).to_not include("color:red")
          expect(view.to_html).to include("color:blue")
        end
      end

      context "when replacing the entire value with a string" do
        before do
          attributes[:style] = "color: red"
        end

        it "is not modified" do
          expect(view.to_html).to_not include("color:red")
          expect(view.to_html).to include("color:blue")
        end
      end

      context "when replacing one key in the value" do
        before do
          attributes[:style][:color] = "red"
        end

        it "is not modified" do
          expect(view.to_html).to_not include("color:red")
          expect(view.to_html).to include("color:blue")
        end
      end
    end

    context "when modifying a set attribute" do
      context "when replacing the entire value with a set" do
        before do
          attributes[:class] = [:baz].to_set
        end

        it "is not modified" do
          expect(view.to_html).to_not include("class=\"baz\"")
          expect(view.to_html).to include("class=\"foo bar\"")
        end
      end

      context "when replacing the entire value with an array" do
        before do
          attributes[:class] = [:baz]
        end

        it "is not modified" do
          expect(view.to_html).to_not include("class=\"baz\"")
          expect(view.to_html).to include("class=\"foo bar\"")
        end
      end

      context "when replacing the entire value with a string" do
        before do
          attributes[:class] = "baz zab"
        end

        it "is not modified" do
          expect(view.to_html).to_not include("class=\"baz zab\"")
          expect(view.to_html).to include("class=\"foo bar\"")
        end
      end

      context "modifying the value" do
        before do
          attributes[:class] << :additional
        end

        it "is not modified" do
          expect(view.to_html).to_not include("class=\"foo bar additional\"")
          expect(view.to_html).to include("class=\"foo bar\"")
        end
      end
    end

    context "when modifying a boolean attribute" do
      context "when setting the value for a nonexistent attribute to true" do
        before do
          attributes[:selected] = true
        end

        it "is not modified" do
          expect(view.to_html).to_not include("selected=\"selected\"")
        end
      end

      context "when setting the value for an existing attribute to false" do
        before do
          attributes[:checked] = false
        end

        it "is not modified" do
          expect(view.to_html).to include("checked=\"checked\"")
        end
      end
    end

    context "when modifying a string attribute" do
      context "when replacing the entire value with a string" do
        before do
          attributes[:title] = "newtitle"
        end

        it "is not modified" do
          expect(view.to_html).to_not include("title=\"newtitle\"")
          expect(view.to_html).to include("title=\"baz\"")
        end
      end

      context "when modifying the value" do
        before do
          attributes[:title].reverse!
        end

        it "is not modified" do
          expect(view.to_html).to_not include("title=\"zab\"")
          expect(view.to_html).to include("title=\"baz\"")
        end
      end
    end
  end
end
