require "pakyow/support/deep_freeze"

RSpec.describe "copying a node that has future transforms" do
  using Pakyow::Support::DeepFreeze

  let :doc do
    StringDoc.new(html)
  end

  let :html do
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
      </head>

      <body>
        <article binding="post">
          <h1 binding="title">title goes here</h1>
        </article>
      </body>
      </html>
    HTML
  end

  let :transformable do
    node = StringDoc::MetaNode.new(
      doc.find_significant_nodes_with_name(:binding, :post)
    )

    node.transform do |meta_node|
      data = ["foo", "bar", "baz"]

      template = meta_node.soft_copy
      insertable = meta_node
      current = meta_node

      data.each do |value|
        current.find_significant_nodes_with_name(:binding, :title)[0].html = value

        unless current.equal?(meta_node)
          insertable.after(current)
          insertable = current
        end

        current = template.soft_copy
      end

      meta_node
    end

    node.transform do |transformable_node|
      transformable_node.attributes[:class] = "red"; transformable_node
    end

    doc
  end

  before do
    @renderable = transformable.deep_freeze
  end

  it "applies the future transforms to each node" do
    expect(@renderable.render).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
        </head>

        <body>
          <article data-b="post" class="red">
            <h1 data-b="title">foo</h1>
          </article>

          <article data-b="post" class="red">
            <h1 data-b="title">bar</h1>
          </article>

          <article data-b="post" class="red">
            <h1 data-b="title">baz</h1>
          </article>
        </body>
        </html>
      HTML
    )
  end

  context "transform conditionally operates on the node" do
    let :presenter_class do
      Class.new(Pakyow::Presenter::Presenter) do
        render :post do
          present(
            [
              { title: "foo" },
              { title: "bar" },
              { title: "baz" }
            ]
          )
        end

        render :post do
          if find(:title).text == "bar"
            attributes[:class] << :red
          end
        end
      end
    end

    let :transformable do
      node = StringDoc::MetaNode.new(
        doc.find_significant_nodes_with_name(:binding, :post)
      )

      node.transform do |meta_node|
        data = ["foo", "bar", "baz"]

        template = meta_node.soft_copy
        insertable = meta_node
        current = meta_node

        data.each do |value|
          current.find_significant_nodes_with_name(:binding, :title)[0].html = value

          unless current.equal?(meta_node)
            insertable.after(current)
            insertable = current
          end

          current = template.soft_copy
        end

        meta_node
      end

      node.transform do |transformable_node|
        if transformable_node.find_significant_nodes_with_name(:binding, :title)[0].text == "bar"
          transformable_node.attributes[:class] = "red"
        end

        transformable_node
      end

      doc
    end

    it "does not change future nodes" do
      expect(@renderable.render).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
          </head>

          <body>
            <article data-b="post">
              <h1 data-b="title">foo</h1>
            </article>

            <article data-b="post" class="red">
              <h1 data-b="title">bar</h1>
            </article>

            <article data-b="post">
              <h1 data-b="title">baz</h1>
            </article>
          </body>
          </html>
        HTML
      )
    end
  end
end
