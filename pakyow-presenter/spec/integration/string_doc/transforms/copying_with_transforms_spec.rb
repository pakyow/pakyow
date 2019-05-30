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

      template = meta_node.dup
      insertable = meta_node
      current = meta_node

      data.each do |value|
        current.find_significant_nodes_with_name(:binding, :title)[0].html = value

        unless current.equal?(meta_node)
          insertable.after(current)
          insertable = current
        end

        current = template.dup
      end

      meta_node
    end

    node.transform do |node|
      node.attributes[:class] = "red"; node
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
          <article data-b="post" data-c="article" class="red">
            <h1 data-b="title" data-c="article">foo</h1>
          </article>

          <article data-b="post" data-c="article" class="red">
            <h1 data-b="title" data-c="article">bar</h1>
          </article>

          <article data-b="post" data-c="article" class="red">
            <h1 data-b="title" data-c="article">baz</h1>
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

        template = meta_node.dup
        insertable = meta_node
        current = meta_node

        data.each do |value|
          current.find_significant_nodes_with_name(:binding, :title)[0].html = value

          unless current.equal?(meta_node)
            insertable.after(current)
            insertable = current
          end

          current = template.dup
        end

        meta_node
      end

      node.transform do |node|
        if node.find_significant_nodes_with_name(:binding, :title)[0].text == "bar"
          node.attributes[:class] = "red"
        end

        node
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
            <article data-b="post" data-c="article">
              <h1 data-b="title" data-c="article">foo</h1>
            </article>

            <article data-b="post" data-c="article" class="red">
              <h1 data-b="title" data-c="article">bar</h1>
            </article>

            <article data-b="post" data-c="article">
              <h1 data-b="title" data-c="article">baz</h1>
            </article>
          </body>
          </html>
        HTML
      )
    end
  end
end
