RSpec.describe StringDoc::Node do
  let :html do
    "<div binding=\"post\"><h1 binding=\"title\">hello</h1></div>"
  end

  let :doc do
    StringDoc.new(html)
  end

  let :node do
    doc.find_significant_nodes_with_name(:binding, :post)[0]
  end

  describe "#attributes" do
    it "returns a StringDoc::Attributes instance" do
      expect(node.attributes).to be_instance_of(StringDoc::Attributes)
    end
  end

  describe "#children" do
    it "returns a StringDoc instance" do
      expect(node.children).to be_instance_of(StringDoc)
    end

    it "actually contains children" do
      expect(node.children.to_s).to eq("<h1 data-b=\"title\">hello</h1>")
    end
  end

  describe "#with_children" do
    context "node has children" do
      it "returns an array containing self, and child nodes" do
        expect(node.with_children.count).to eq(3)
        expect(node.with_children[0]).to be(node)
        expect(node.with_children[1]).to eq(node.children.nodes[0])
        expect(node.with_children[2]).to eq(node.children.nodes[0].children.nodes[0])
      end
    end

    context "node does not have children" do
      before do
        node.clear
      end

      it "returns an array containing self" do
        expect(node.with_children.count).to eq(1)
        expect(node.with_children[0]).to be(node)
      end
    end
  end

  describe "#replace" do
    context "replacement is a StringDoc" do
      it "replaces" do
        replacement = StringDoc.new("foo")
        doc.find_significant_nodes_with_name(:binding, :title)[0].replace(replacement)
        expect(doc.to_s).to eq("<div data-b=\"post\">foo</div>")
      end

      it "maintains internal state" do
        node = doc.find_significant_nodes_with_name(:binding, :title)[0]
        node.instance_variable_set(:@labels, { foo: "bar" })
        node.replace(StringDoc.new("foo"))
        expect(node.label(:foo)).to eq("bar")
      end
    end

    context "replacement is a StringDoc::Node" do
      it "replaces" do
        replacement = node.dup
        doc.find_significant_nodes_with_name(:binding, :title)[0].replace(replacement)
        expect(doc.to_s).to eq("<div data-b=\"post\"><div data-b=\"post\"><h1 data-b=\"title\">hello</h1></div></div>")
      end

      it "maintains internal state" do
        node = doc.find_significant_nodes_with_name(:binding, :title)[0]
        node.instance_variable_set(:@labels, { foo: "bar" })
        node.replace(node.dup)
        expect(node.label(:foo)).to eq("bar")
      end

      context "removing a node that has been used as a replacement" do
        it "properly removes the replacement node" do
          replacement = node.dup
          doc.find_significant_nodes_with_name(:binding, :title)[0].replace(replacement)
          replacement.remove
          expect(doc.to_html).to eq("<div data-b=\"post\"></div>")
        end
      end
    end

    context "replacement is another object" do
      it "replaces" do
        replacement = "foo"
        doc.find_significant_nodes_with_name(:binding, :title)[0].replace(replacement)
        expect(doc.to_s).to eq("<div data-b=\"post\">foo</div>")
      end
    end
  end

  describe "#remove" do
    context "node is primary" do
      it "removes the node" do
        node.remove
        expect(doc.to_s).to eq("")
      end
    end

    context "node is a child" do
      it "removes the node" do
        doc.find_significant_nodes_with_name(:binding, :title)[0].remove
        expect(doc.to_s).to eq("<div data-b=\"post\"></div>")
      end
    end
  end

  describe "#text" do
    it "returns the text value of the current node" do
      expect(doc.find_significant_nodes_with_name(:binding, :title)[0].text).to eq("hello")
    end

    context "node has children" do
      it "includes the text values from children" do
        expect(node.text).to eq("hello")
      end
    end
  end

  describe "#html" do
    it "returns the html value of the current node's children" do
      expect(doc.find_significant_nodes_with_name(:binding, :title)[0].html).to eq("hello")
    end

    context "node has children" do
      it "includes the childen in the value" do
        expect(node.html).to eq("<h1 data-b=\"title\">hello</h1>")
      end
    end
  end

  describe "#html=" do
    it "sets the html value of the current node" do
      node = doc.find_significant_nodes_with_name(:binding, :title)[0]
      node.html = "<div>foo</div>"
      expect(node.to_s).to eq("<h1 data-b=\"title\"><div>foo</div></h1>")
    end

    context "node has children" do
      it "replaces the childen" do
        node.html = "<div>foo</div>"
        expect(node.to_s).to eq("<div data-b=\"post\"><div>foo</div></div>")
      end
    end
  end

  describe "#replace_children" do
    it "sets the html value of the current node" do
      node = doc.find_significant_nodes_with_name(:binding, :title)[0]
      node.replace_children("<div>foo</div>")
      expect(node.to_s).to eq("<h1 data-b=\"title\"><div>foo</div></h1>")
    end

    context "node has children" do
      it "replaces the childen" do
        node.replace_children("<div>foo</div>")
        expect(node.to_s).to eq("<div data-b=\"post\"><div>foo</div></div>")
      end
    end

    context "new children have significant nodes" do
      it "finds the significant nodes" do
        node.replace_children("<div binding=\"foo\">foo</div>")
        expect(doc.find_significant_nodes_with_name(:binding, :foo).count).to eq(1)
      end
    end
  end

  describe "#tagname" do
    it "returns the tagname" do
      expect(node.tagname).to eq("div")
    end
  end

  describe "#clear" do
    it "removes children" do
      node.clear
      expect(node.to_s).to eq("<div data-b=\"post\"></div>")
    end
  end

  describe "#after" do
    context "passed a StringDoc" do
      let :insertable do
        StringDoc.new("<div>insertable</div>")
      end

      it "inserts after self" do
        node.after(insertable)
        expect(doc.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">hello</h1></div><div>insertable</div>")
      end
    end

    context "passed a StringDoc::Node" do
      let :insertable do
        StringDoc.new("<div>insertable</div>").nodes[0]
      end

      it "inserts after self" do
        node.after(insertable)
        expect(doc.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">hello</h1></div><div>insertable</div>")
      end
    end

    context "passed another object" do
      let :insertable do
        "<div>insertable</div>"
      end

      it "inserts after self" do
        node.after(insertable)
        expect(doc.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">hello</h1></div><div>insertable</div>")
      end
    end
  end

  describe "#before" do
    context "passed a StringDoc" do
      let :insertable do
        StringDoc.new("<div>insertable</div>")
      end

      it "inserts before self" do
        node.before(insertable)
        expect(doc.to_s).to eq("<div>insertable</div><div data-b=\"post\"><h1 data-b=\"title\">hello</h1></div>")
      end
    end

    context "passed a StringDoc::Node" do
      let :insertable do
        StringDoc.new("<div>insertable</div>").nodes[0]
      end

      it "inserts before self" do
        node.before(insertable)
        expect(doc.to_s).to eq("<div>insertable</div><div data-b=\"post\"><h1 data-b=\"title\">hello</h1></div>")
      end
    end

    context "passed another object" do
      let :insertable do
        "<div>insertable</div>"
      end

      it "inserts before self" do
        node.before(insertable)
        expect(doc.to_s).to eq("<div>insertable</div><div data-b=\"post\"><h1 data-b=\"title\">hello</h1></div>")
      end
    end
  end

  describe "#append" do
    context "passed a StringDoc" do
      let :insertable do
        StringDoc.new("<div>insertable</div>")
      end

      it "appends to self" do
        node.append(insertable)
        expect(doc.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">hello</h1><div>insertable</div></div>")
      end
    end

    context "passed a StringDoc::Node" do
      let :insertable do
        StringDoc.new("<div>insertable</div>").nodes[0]
      end

      it "appends to self" do
        node.append(insertable)
        expect(doc.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">hello</h1><div>insertable</div></div>")
      end
    end

    context "passed another object" do
      let :insertable do
        "<div>insertable</div>"
      end

      it "appends to self" do
        node.append(insertable)
        expect(doc.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">hello</h1><div>insertable</div></div>")
      end
    end
  end

  describe "#prepend" do
    context "passed a StringDoc" do
      let :insertable do
        StringDoc.new("<div>insertable</div>")
      end

      it "prepends to self" do
        node.prepend(insertable)
        expect(doc.to_s).to eq("<div data-b=\"post\"><div>insertable</div><h1 data-b=\"title\">hello</h1></div>")
      end
    end

    context "passed a StringDoc::Node" do
      let :insertable do
        StringDoc.new("<div>insertable</div>").nodes[0]
      end

      it "prepends to self" do
        node.prepend(insertable)
        expect(doc.to_s).to eq("<div data-b=\"post\"><div>insertable</div><h1 data-b=\"title\">hello</h1></div>")
      end
    end

    context "passed another object" do
      let :insertable do
        "<div>insertable</div>"
      end

      it "prepends to self" do
        node.prepend(insertable)
        expect(doc.to_s).to eq("<div data-b=\"post\"><div>insertable</div><h1 data-b=\"title\">hello</h1></div>")
      end
    end
  end

  describe "#label" do
    let :html do
      "<div binding=\"post\" version=\"foo\"><h1 binding=\"title\">hello</h1></div>"
    end

    context "label exists" do
      it "returns the value" do
        expect(node.label(:version)).to eq(:foo)
      end
    end

    context "label does not exist" do
      it "returns nil" do
        expect(node.label(:nonexistent)).to eq(nil)
      end
    end
  end

  describe "#labeled?" do
    let :html do
      "<div binding=\"post\" version=\"foo\"><h1 binding=\"title\">hello</h1></div>"
    end

    context "label exists" do
      it "returns true" do
        expect(node.labeled?(:version)).to eq(true)
      end
    end

    context "label does not exist" do
      it "returns false" do
        expect(node.labeled?(:nonexistent)).to eq(false)
      end
    end
  end

  describe "#delete_label" do
    let :html do
      "<div binding=\"post\" version=\"foo\"><h1 binding=\"title\">hello</h1></div>"
    end

    context "label exists" do
      it "deletes the label" do
        expect(node.label(:version)).to eq(:foo)
        expect(node.labeled?(:version)).to eq(true)
        node.delete_label(:version)
        expect(node.label(:version)).to eq(nil)
        expect(node.labeled?(:version)).to eq(false)
      end
    end

    context "label does not exist" do
      it "does not error" do
        expect(node.label(:nonexistent)).to eq(nil)
        expect(node.labeled?(:nonexistent)).to eq(false)
        node.delete_label(:nonexistent)
        expect(node.label(:nonexistent)).to eq(nil)
        expect(node.labeled?(:nonexistent)).to eq(false)
      end
    end
  end

  describe "#to_xml" do
    it "converts the document to an xml string" do
      expect(node.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">hello</h1></div>")
    end
  end

  describe "#to_html" do
    it "converts the document to an xml string" do
      expect(node.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">hello</h1></div>")
    end
  end

  describe "#to_s" do
    it "converts the document to an xml string" do
      expect(node.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">hello</h1></div>")
    end
  end

  describe "#inspect" do
    it "includes significance" do
      expect(node.inspect).to include("@significance=[:binding, :within_binding]")
    end

    it "includes labels" do
      expect(node.inspect).to include("@labels={:binding=>:title, :channel=>[], :combined_channel=>\"\"}")
    end

    it "includes attributes" do
      expect(node.inspect).to include("@attributes=#<StringDoc::Attributes")
    end

    it "includes children" do
      expect(node.inspect).to include("@children=#<StringDoc")
    end

    it "does not include node" do
      expect(node.inspect).not_to include("@node=")
    end
  end

  describe "#==" do
    it "returns true when the nodes are equal" do
      comparison = StringDoc.new(html).nodes[0]
      expect(node == comparison).to be true
    end

    it "returns false when the nodes are not equal" do
      comparison = StringDoc.new("<div binding=\"post\"><h1 binding=\"title\">goodbye</h1></div>").nodes[0]
      expect(node == comparison).to be false
    end

    it "returns false when the comparison is not a StringDoc::Node" do
      expect(node == "").to be false
    end
  end
end
