require "string_doc"

RSpec.describe StringDoc do
  let :doc do
    StringDoc.new(html)
  end

  describe "#initialize" do
    it "initializes with an xml string" do
      expect(StringDoc.new("<div></div>")).to be_instance_of(StringDoc)
    end
  end

  describe "#find_significant_nodes" do
    let :html do
      "<div binding=\"post\"><h1 binding=\"title\"></h1><p binding=\"body\"></p></div>"
    end

    context "nodes of the type are found" do
      it "returns the found nodes" do
        nodes = doc.find_significant_nodes(:binding)
        expect(nodes.count).to eq(1)
        expect(nodes.first).to be_instance_of(StringDoc::Node)
      end
    end

    context "no nodes of the type are found" do
      it "returns an empty array" do
        nodes = doc.find_significant_nodes(:body)
        expect(nodes).to eq([])
      end
    end

    context "doc contains significant children" do
      it "does not return children" do
        nodes = doc.find_significant_nodes(:binding)
        expect(nodes.count).to eq(1)
      end
    end
  end

  describe "#find_significant_nodes_with_name" do
    let :html do
      "<div binding=\"post\"><h1 binding=\"title\"></h1><p binding=\"body\"></p></div>"
    end

    context "nodes of the type and name are found" do
      it "returns the found nodes" do
        nodes = doc.find_significant_nodes_with_name(:binding, :post)
        expect(nodes.count).to eq(1)
        expect(nodes.first).to be_instance_of(StringDoc::Node)
      end
    end

    context "no nodes of the type and name are found" do
      it "returns an empty array" do
        nodes = doc.find_significant_nodes_with_name(:binding, :foo)
        expect(nodes).to eq([])
      end
    end

    context "doc contains significant children" do
      it "does not return children" do
        nodes = doc.find_significant_nodes_with_name(:binding, :title)
        expect(nodes.count).to eq(0)
      end
    end
  end

  describe "#clear" do
    let :html do
      "<div>foo</div>"
    end

    it "clears the nodes" do
      doc.clear
      expect(doc.to_html).to eq("")
    end

    it "returns self" do
      expect(doc.clear).to be(doc)
    end
  end

  describe "#replace" do
    let :html do
      "<div>foo</div>"
    end

    context "passed a StringDoc" do
      let :replacement do
        StringDoc.new("replacement")
      end

      it "replaces the current doc with the replacement" do
        doc.replace(replacement)
        expect(doc.to_html).to eq("replacement")
      end

      it "returns self" do
        expect(doc.replace(replacement)).to be(doc)
      end
    end

    context "passed another object" do
      let :replacement do
        "replacement"
      end

      it "replaces the current doc with the replacement" do
        doc.replace(replacement)
        expect(doc.to_html).to eq("replacement")
      end

      it "returns self" do
        expect(doc.replace(replacement)).to be(doc)
      end
    end
  end

  describe "#append" do
    let :html do
      "<div>foo</div>"
    end

    context "passed a StringDoc" do
      let :child do
        StringDoc.new("child")
      end

      it "appends as a child" do
        doc.append(child)
        expect(doc.to_html).to eq("<div>foo</div>child")
      end

      it "returns self" do
        expect(doc.append(child)).to be(doc)
      end
    end

    context "passed another object" do
      let :child do
        "child"
      end

      it "appends as a child" do
        doc.append(child)
        expect(doc.to_html).to eq("<div>foo</div>child")
      end

      it "returns self" do
        expect(doc.append(child)).to be(doc)
      end
    end
  end

  describe "#prepend" do
    let :html do
      "<div>foo</div>"
    end

    context "passed a StringDoc" do
      let :child do
        StringDoc.new("child")
      end

      it "prepends as a child" do
        doc.prepend(child)
        expect(doc.to_html).to eq("child<div>foo</div>")
      end

      it "returns self" do
        expect(doc.prepend(child)).to be(doc)
      end
    end

    context "passed another object" do
      let :child do
        "child"
      end

      it "prepends as a child" do
        doc.prepend(child)
        expect(doc.to_html).to eq("child<div>foo</div>")
      end

      it "returns self" do
        expect(doc.prepend(child)).to be(doc)
      end
    end
  end

  describe "#insert_after" do
    let :html do
      "<div>foo</div><div>bar</div><div>baz</div>"
    end

    context "node to insert after is found" do
      context "passed a StringDoc" do
        let :child do
          StringDoc.new("child")
        end

        let :node do
          doc.nodes[1]
        end

        it "inserts after the specified node" do
          doc.insert_after(child, node)
          expect(doc.to_html).to eq("<div>foo</div><div>bar</div>child<div>baz</div>")
        end

        it "returns self" do
          expect(doc.insert_after(child, node)).to be(doc)
        end
      end

      context "passed a StringDoc::Node" do
        let :child do
          StringDoc.new("child").nodes[0]
        end

        let :node do
          doc.nodes[1]
        end

        it "inserts after the specified node" do
          doc.insert_after(child, node)
          expect(doc.to_html).to eq("<div>foo</div><div>bar</div>child<div>baz</div>")
        end

        it "returns self" do
          expect(doc.insert_after(child, node)).to be(doc)
        end
      end

      context "passed another object" do
        let :child do
          "child"
        end

        let :node do
          doc.nodes[2]
        end

        it "inserts after the specified node" do
          doc.insert_after(child, node)
          expect(doc.to_html).to eq("<div>foo</div><div>bar</div><div>baz</div>child")
        end

        it "returns self" do
          expect(doc.insert_after(child, node)).to be(doc)
        end
      end
    end

    context "node to insert after is not found" do
      let :child do
        "child"
      end

      let :node do
        StringDoc::Node.new
      end

      it "does not insert" do
        doc.insert_after(child, node)
        expect(doc.to_html).to eq("<div>foo</div><div>bar</div><div>baz</div>")
      end

      it "returns self" do
        expect(doc.insert_after(child, node)).to be(doc)
      end
    end
  end

  describe "#insert_before" do
    let :html do
      "<div>foo</div><div>bar</div><div>baz</div>"
    end

    context "node to insert before is found" do
      context "passed a StringDoc" do
        let :child do
          StringDoc.new("child")
        end

        let :node do
          doc.nodes[1]
        end

        it "inserts before the specified node" do
          doc.insert_before(child, node)
          expect(doc.to_html).to eq("<div>foo</div>child<div>bar</div><div>baz</div>")
        end

        it "returns self" do
          expect(doc.insert_before(child, node)).to be(doc)
        end
      end

      context "passed a StringDoc::Node" do
        let :child do
          StringDoc.new("child").nodes[0]
        end

        let :node do
          doc.nodes[1]
        end

        it "inserts before the specified node" do
          doc.insert_before(child, node)
          expect(doc.to_html).to eq("<div>foo</div>child<div>bar</div><div>baz</div>")
        end

        it "returns self" do
          expect(doc.insert_before(child, node)).to be(doc)
        end
      end

      context "passed another object" do
        let :child do
          "child"
        end

        let :node do
          doc.nodes[2]
        end

        it "inserts before the specified node" do
          doc.insert_before(child, node)
          expect(doc.to_html).to eq("<div>foo</div><div>bar</div>child<div>baz</div>")
        end

        it "returns self" do
          expect(doc.insert_before(child, node)).to be(doc)
        end
      end
    end

    context "node to insert before is not found" do
      let :child do
        "child"
      end

      let :node do
        StringDoc::Node.new
      end

      it "does not insert" do
        doc.insert_before(child, node)
        expect(doc.to_html).to eq("<div>foo</div><div>bar</div><div>baz</div>")
      end

      it "returns self" do
        expect(doc.insert_before(child, node)).to be(doc)
      end
    end
  end

  describe "#remove_node" do
    let :html do
      "<div>foo</div><div>bar</div><div>baz</div>"
    end

    before do
      expect(doc.nodes.count).to eq(3)
    end

    context "the node exists" do
      it "deletes the mode" do
        doc.remove_node(doc.nodes[2])
        expect(doc.nodes.count).to eq(2)
        expect(doc.render).to eq("<div>foo</div><div>bar</div>")
      end

      it "returns self" do
        expect(doc.remove_node(doc.nodes[2])).to be(doc)
      end
    end

    context "the node does not exist" do
      it "returns self" do
        expect(doc.remove_node(StringDoc::Node.new)).to be(doc)
        expect(doc.nodes.count).to eq(3)
      end
    end

    context "the node to remove is not a node" do
      it "returns self" do
        expect(doc.remove_node(:hi)).to be(doc)
        expect(doc.nodes.count).to eq(3)
      end
    end
  end

  describe "#replace_node" do
    let :html do
      "<div>foo</div><div>bar</div><div>baz</div>"
    end

    before do
      expect(doc.nodes.count).to eq(3)
    end

    context "the node exists" do
      context "replacement is a StringDoc" do
        let :replacement do
          StringDoc.new("<div>replacement</div>")
        end

        it "replaces the mode" do
          doc.replace_node(doc.nodes[2], replacement)
          expect(doc.nodes.count).to eq(3)
          expect(doc.render).to eq("<div>foo</div><div>bar</div><div>replacement</div>")
        end

        it "returns self" do
          expect(doc.replace_node(doc.nodes[2], replacement)).to be(doc)
        end
      end

      context "replacement is a StringDoc::Node" do
        let :replacement do
          StringDoc.new("<div>replacement</div>").nodes[0]
        end

        it "replaces the mode" do
          doc.replace_node(doc.nodes[2], replacement)
          expect(doc.nodes.count).to eq(3)
          expect(doc.render).to eq("<div>foo</div><div>bar</div><div>replacement</div>")
        end

        it "returns self" do
          expect(doc.replace_node(doc.nodes[2], replacement)).to be(doc)
        end
      end

      context "replacement is another object" do
        let :replacement do
          "<div>replacement</div>"
        end

        it "replaces the mode" do
          doc.replace_node(doc.nodes[2], replacement)
          expect(doc.nodes.count).to eq(3)
          expect(doc.render).to eq("<div>foo</div><div>bar</div><div>replacement</div>")
        end

        it "returns self" do
          expect(doc.replace_node(doc.nodes[2], replacement)).to be(doc)
        end
      end
    end

    context "the node does not exist" do
      let :replacement do
        StringDoc.new("<div>replacement</div>")
      end

      it "returns self" do
        expect(doc.replace_node(StringDoc::Node.new, replacement)).to be(doc)
        expect(doc.nodes.count).to eq(3)
      end
    end

    context "the node to replace is not a node" do
      let :replacement do
        StringDoc.new("<div>replacement</div>")
      end

      it "returns self" do
        expect(doc.replace_node(:hi, replacement)).to be(doc)
        expect(doc.nodes.count).to eq(3)
      end
    end
  end

  describe "#to_xml" do
    let :html do
      "<div>foo</div>"
    end

    it "converts the document to an xml string" do
      expect(doc.to_xml).to eq(html)
    end
  end

  describe "#to_html" do
    let :html do
      "<div>foo</div>"
    end

    it "converts the document to an xml string" do
      expect(doc.to_xml).to eq(html)
    end
  end

  describe "#to_s" do
    let :html do
      "<div>foo</div>"
    end

    it "converts the document to an xml string" do
      expect(doc.to_xml).to eq(html)
    end
  end

  describe "#==" do
    let :html do
      "<div>foo</div>"
    end

    it "returns true when the documents are equal" do
      comparison = StringDoc.new(html)
      expect(doc == comparison).to be true
    end

    it "returns false when the documents are not equal" do
      comparison = StringDoc.new("<div>bar</div>")
      expect(doc == comparison).to be false
    end

    it "returns false when the comparison is not a StringDoc" do
      expect(doc == "").to be false
    end
  end

  describe "#collapse" do
    context "document has no significant nodes" do
      let :html do
        "<div>foo</div>"
      end

      before do
        doc.collapse
      end

      it "converts to a string correctly" do
        expect(doc.to_s).to eq("<div>foo</div>")
      end

      it "renders correctly" do
        expect(doc.render).to eq("<div>foo</div>")
      end
    end

    context "document has nodes of many significant types" do
      let :html do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>test</title>
            </head>
            <body>
              <header>
                <h1>
                  test
                </h1>
              </header>

              <main>
                <form binding="message">
                  <input type="text" binding="content">
                </form>

                <div binding="message">
                  <h1 binding="content">
                    content goes here
                  </h1>

                  <div binding="comment">
                    <p binding="body">
                      body goes here
                    </p>
                  </div>
                </div>
              </main>

              <footer>
                <a href="mailto:hello@pakyow.com">hello@pakyow.com</a>
              </footer>
            </body>
          </html>
        HTML
      end

      before do
        doc.collapse(:form)
      end

      it "converts to a string correctly" do
        expect(doc.to_s).to eq(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>test</title>
              </head>
              <body>
                <header>
                  <h1>
                    test
                  </h1>
                </header>

                <main>
                  <form data-b="message:form">
                    <input type="text" data-b="content">
                  </form>

                  <div data-b="message">
                    <h1 data-b="content">
                      content goes here
                    </h1>

                    <div data-b="comment">
                      <p data-b="body">
                        body goes here
                      </p>
                    </div>
                  </div>
                </main>

                <footer>
                  <a href="mailto:hello@pakyow.com">hello@pakyow.com</a>
                </footer>
              </body>
            </html>
          HTML
        )
      end

      it "renders correctly" do
        expect(doc.to_s).to eq(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>test</title>
              </head>
              <body>
                <header>
                  <h1>
                    test
                  </h1>
                </header>

                <main>
                  <form data-b="message:form">
                    <input type="text" data-b="content">
                  </form>

                  <div data-b="message">
                    <h1 data-b="content">
                      content goes here
                    </h1>

                    <div data-b="comment">
                      <p data-b="body">
                        body goes here
                      </p>
                    </div>
                  </div>
                </main>

                <footer>
                  <a href="mailto:hello@pakyow.com">hello@pakyow.com</a>
                </footer>
              </body>
            </html>
          HTML
        )
      end

      it "collapses the correct nodes" do
        expect(doc.each.map(&:itself).count).to eq(21)
      end
    end
  end

  describe "transforming a collapsed doc" do
    # FIXME: This is currently broken and needs to be fixed at some point.
    #
    it "renders correctly"
  end
end
