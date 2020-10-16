RSpec.describe "significant node labels" do
  let :node do
    view.object.nodes.first
  end

  describe "labels" do
    describe "ui" do
      let :view do
        Pakyow::Presenter::View.new <<~HTML
          <body ui="foo"></body>
        HTML
      end

      it "is a label" do
        expect(node.label(:ui)).to eq(:foo)
      end
    end

    describe "version" do
      let :view do
        Pakyow::Presenter::View.new <<~HTML
          <body version="foo"></body>
        HTML
      end

      it "is a label" do
        expect(node.label(:version)).to eq(:foo)
      end
    end

    describe "include" do
      let :view do
        Pakyow::Presenter::View.new <<~HTML
          <body include="foo"></body>
        HTML
      end

      it "is a label" do
        expect(node.label(:include)).to eq(:foo)
      end
    end

    describe "exclude" do
      let :view do
        Pakyow::Presenter::View.new <<~HTML
          <body exclude="foo"></body>
        HTML
      end

      it "is a label" do
        expect(node.label(:exclude)).to eq(:foo)
      end
    end

    describe "endpoint" do
      let :view do
        Pakyow::Presenter::View.new <<~HTML
          <body endpoint="foo"></body>
        HTML
      end

      it "is a label" do
        expect(node.label(:endpoint)).to eq(:foo)
      end
    end
  end

  describe "node with multiple labels" do
    let :view do
      Pakyow::Presenter::View.new <<~HTML
        <body ui="foo" endpoint="foo"></body>
      HTML
    end

    it "contains each label" do
      expect(node.label(:ui)).to eq(:foo)
      expect(node.label(:endpoint)).to eq(:foo)
    end
  end

  describe "unlabeled node" do
    let :view do
      Pakyow::Presenter::View.new <<~HTML
        <body></body>
      HTML
    end

    it "contains no labels" do
      expect(node.label(:ui)).to be_nil
    end
  end
end
