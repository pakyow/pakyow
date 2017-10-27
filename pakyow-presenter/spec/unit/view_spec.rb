RSpec.describe Pakyow::Presenter::View do
  describe "#attributes" do
    let :html do
      "<div@post style=\"color: blue\"></div>"
    end

    let :doc do
      Pakyow::Presenter::StringDoc.new(html)
    end

    let :view do
      Pakyow::Presenter::View.new(object: doc.nodes.first)
    end

    context "when `object` is a StringDoc" do
      let :view do
        Pakyow::Presenter::View.new(object: doc)
      end

      it "does not raise error" do
        expect { view.attributes }.not_to raise_error
      end

      it "returns nil" do
        expect(view.attributes).to eq(nil)
      end
    end

    context "when `object` is a StringNode" do
      context "when `object` is significant" do
        let :attributes do
          view.attributes
        end

        it "returns an instance of `Attributes`" do
          expect(attributes).to be_instance_of(Pakyow::Presenter::ViewAttributes)
        end
      end

      context "when `object` is insignificant" do
        let :html do
          "<div style=\"color: blue\"></div>"
        end

        it "returns an instance of `Attributes`" do
          expect(view.attributes).to be_instance_of(Pakyow::Presenter::ViewAttributes)
        end
      end
    end
  end
end
