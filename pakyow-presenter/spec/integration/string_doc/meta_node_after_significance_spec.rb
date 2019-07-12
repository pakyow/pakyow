RSpec.describe "finding significant nodes appended to a meta node" do
  let :node do
    StringDoc::MetaNode.new(
      StringDoc.new(
        <<~HTML
          <div>
            <div binding="foo"></div>
          </div>
        HTML
      ).find_significant_nodes(:binding)
    )
  end

  it "does not return the appended node" do
    node.after('<div><label></label></div>')
    expect(node.find_significant_nodes(:label, descend: true).count).to eq(0)
  end
end
