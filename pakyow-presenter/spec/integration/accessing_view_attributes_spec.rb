RSpec.describe "accessing view attributes" do
  let :html do
    "<div binding=\"post\" style=\"color: blue\" class=\"foo bar\" title=\"baz\" checked=\"checked\"></div>"
  end

  let :doc do
    StringDoc.new(html)
  end

  let :view do
    Pakyow::Presenter::View.from_object(doc.nodes.first)
  end

  let :attributes do
    view.attributes
  end

  context "when attribute is of type hash" do
    let :value do
      attributes[:style]
    end

    it "is the proper type" do
      expect(value).to be_instance_of(Pakyow::Presenter::Attributes::Hash)
    end

    it "contains the values from the view" do
      expect(value).to eq({ color: "blue" })
    end
  end

  context "when attribute is of type set" do
    let :value do
      attributes[:class]
    end

    it "is the proper type" do
      expect(value).to be_instance_of(Pakyow::Presenter::Attributes::Set)
    end

    it "contains the values from the view" do
      expect(value).to be_instance_of(Pakyow::Presenter::Attributes::Set)
      expect(value.to_a).to eq([:foo, :bar])
    end
  end

  context "when attribute is of type boolean" do
    let :value do
      attributes[:checked]
    end

    it "is the proper type" do
      expect(value).to be(true)
    end

    it "contains the values from the view" do
      expect(value).to be_truthy
    end

    context "when attribute is not present in the view" do
      it "defaults to false" do
        expect(attributes[:selected]).to be(false)
      end
    end
  end

  context "when attribute is of type string" do
    let :value do
      attributes[:title]
    end

    it "is the proper type" do
      expect(value).to be_instance_of(Pakyow::Presenter::Attributes::String)
    end

    it "contains the values from the view" do
      expect(value).to eq("baz")
    end
  end

  context "when the view has no attributes" do
    let :html do
      "<div binding=\"post\"></div>"
    end

    describe "attributes" do
      it "is empty" do
        expect(view.attributes).to be_instance_of(Pakyow::Presenter::ViewAttributes)
      end
    end
  end
end
