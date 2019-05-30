require "pakyow/support/deep_freeze"

RSpec.describe "StringDoc transforms" do
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

  context "transforms the passed node" do
    before do
      doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do |node|
        node.html = "hello"; node
      end

      @renderable = doc.deep_freeze
    end

    it "transforms on render" do
      expect(@renderable.render).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
          </head>

          <body>
            <article data-b="post" data-c="article">
              <h1 data-b="title" data-c="article">hello</h1>
            </article>
          </body>
          </html>
        HTML
      )
    end
  end

  context "no transforms" do
    before do
      @renderable = doc.deep_freeze
    end

    it "renders" do
      expect(@renderable.render).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
          </head>

          <body>
            <article data-b="post" data-c="article">
              <h1 data-b="title" data-c="article">title goes here</h1>
            </article>
          </body>
          </html>
        HTML
      )
    end
  end

  context "transform returns nil" do
    before do
      doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do
        nil
      end

      @renderable = doc.deep_freeze
    end

    it "removes the node" do
      expect(@renderable.render).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
          </head>

          <body>
            <article data-b="post" data-c="article"></article>
          </body>
          </html>
        HTML
      )
    end
  end

  context "transform returns string" do
    before do
      doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do
        "hello"
      end

      @renderable = doc.deep_freeze
    end

    it "renders the string in place of the node" do
      expect(@renderable.render).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
          </head>

          <body>
            <article data-b="post" data-c="article">
              hello
            </article>
          </body>
          </html>
        HTML
      )
    end
  end

  context "transform returns node" do
    before do
      doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do
        StringDoc::Node.new("hello")
      end

      @renderable = doc.deep_freeze
    end

    it "renders the node" do
      expect(@renderable.render).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
          </head>

          <body>
            <article data-b="post" data-c="article">
              hello
            </article>
          </body>
          </html>
        HTML
      )
    end
  end

  context "transform returns doc" do
    before do
      doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do
        StringDoc.new("hello")
      end

      @renderable = doc.deep_freeze
    end

    it "renders the doc" do
      expect(@renderable.render).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
          </head>

          <body>
            <article data-b="post" data-c="article">
              hello
            </article>
          </body>
          </html>
        HTML
      )
    end
  end

  context "multiple transforms for different nodes" do
    before do
      doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do
        "hello"
      end

      doc.find_significant_nodes(:meta)[0].transform do |node|
        node.attributes[:content] = "test"; node
      end

      @renderable = doc.deep_freeze
    end

    it "transforms on render" do
      expect(@renderable.render).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8" content="test">
          </head>

          <body>
            <article data-b="post" data-c="article">
              hello
            </article>
          </body>
          </html>
        HTML
      )
    end
  end

  context "multiple transforms on the same node" do
    context "transforms all return nodes" do
      before do
        doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do |node|
          node.html = "hello"; node
        end

        doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do |node|
          node.attributes[:class] = "foo"; node
        end

        @renderable = doc.deep_freeze
      end

      it "transforms on render" do
        expect(@renderable.render).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
            </head>

            <body>
              <article data-b="post" data-c="article">
                <h1 data-b="title" data-c="article" class="foo">hello</h1>
              </article>
            </body>
            </html>
          HTML
        )
      end
    end

    context "transformation returns nil" do
      before do
        doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do
          nil
        end

        doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do |node|
          node.html = "hello"; node
        end

        @renderable = doc.deep_freeze
      end

      it "removes the node without applying future transforms" do
        expect(@renderable.render).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
            </head>

            <body>
              <article data-b="post" data-c="article">
              </article>
            </body>
            </html>
          HTML
        )
      end
    end

    context "transformation returns string" do
      before do
        doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do
          "hello"
        end

        doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do |node|
          node.html = "hello"; node
        end

        @renderable = doc.deep_freeze
      end

      it "replaces the node without applying future transforms" do
        expect(@renderable.render).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
            </head>

            <body>
              <article data-b="post" data-c="article">
                hello
              </article>
            </body>
            </html>
          HTML
        )
      end
    end

    describe "transform priority" do
      before do
        doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do
          "hello"
        end

        doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform priority: :high do
          nil
        end

        @renderable = doc.deep_freeze
      end

      it "applies transforms in order of priority" do
        expect(@renderable.render).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
            </head>

            <body>
              <article data-b="post" data-c="article">
              </article>
            </body>
            </html>
          HTML
        )
      end
    end
  end

  context "transformed node's parent was transformed" do
    before do
      doc.find_significant_nodes_with_name(:binding, :post)[0].transform do |node|
        node.attributes[:class] = "foo"; node
      end

      doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do |node|
        node.html = "hello"; node
      end

      @renderable = doc.deep_freeze
    end

    it "transforms on render" do
      expect(@renderable.render).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
          </head>

          <body>
            <article data-b="post" data-c="article" class="foo">
              <h1 data-b="title" data-c="article">hello</h1>
            </article>
          </body>
          </html>
        HTML
      )
    end
  end

  describe "transforming multiple nodes as one" do
    let :html do
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
        </head>

        <body>
          <article binding="post">
            <h1 binding="title">1 title goes here</h1>
          </article>

          <article binding="post">
            <h1 binding="title">2 title goes here</h1>
          </article>
        </body>
        </html>
      HTML
    end

    context "all nodes are transformed" do
      before do
        counter = 0
        StringDoc::MetaNode.new(
          doc.find_significant_nodes_with_name(:binding, :post)
        ).transform do |meta_node|
          counter += 1

          meta_node.nodes.each do |node|
            node.html = counter.to_s
          end

          meta_node
        end

        @renderable = doc.deep_freeze
      end

      it "transforms on render" do
        expect(@renderable.render).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
            </head>

            <body>
              <article data-b="post" data-c="article">
                1
              </article>

              <article data-b="post" data-c="article">
                1
              </article>
            </body>
            </html>
          HTML
        )
      end
    end

    context "node is removed" do
      before do
        StringDoc::MetaNode.new(
          doc.find_significant_nodes_with_name(:binding, :post)
        ).transform do |meta_node|
          meta_node.nodes[1].remove; meta_node
        end

        @renderable = doc.deep_freeze
      end

      it "transforms on render" do
        expect(@renderable.render).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
            </head>

            <body>
              <article data-b="post" data-c="article">
                <h1 data-b="title" data-c="article">1 title goes here</h1>
              </article>
            </body>
            </html>
          HTML
        )
      end
    end

    context "node is replaced" do
      before do
        StringDoc::MetaNode.new(
          doc.find_significant_nodes_with_name(:binding, :post)
        ).transform do |meta_node|
          meta_node.nodes[1].replace(StringDoc::Node.new("replaced")); meta_node
        end

        @renderable = doc.deep_freeze
      end

      it "transforms on render" do
        expect(@renderable.render).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
            </head>

            <body>
              <article data-b="post" data-c="article">
                <h1 data-b="title" data-c="article">1 title goes here</h1>
              </article>

              replaced
            </body>
            </html>
          HTML
        )
      end
    end

    context "node is inserted after" do
      before do
        StringDoc::MetaNode.new(
          doc.find_significant_nodes_with_name(:binding, :post)
        ).transform do |meta_node|
          meta_node.nodes[0].after(StringDoc::Node.new("insert")); meta_node
        end

        @renderable = doc.deep_freeze
      end

      it "transforms on render" do
        expect(@renderable.render).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
            </head>

            <body>
              <article data-b="post" data-c="article">
                <h1 data-b="title" data-c="article">1 title goes here</h1>
              </article>

              insert

              <article data-b="post" data-c="article">
                <h1 data-b="title" data-c="article">2 title goes here</h1>
              </article>
            </body>
            </html>
          HTML
        )
      end
    end

    context "node is inserted before" do
      before do
        StringDoc::MetaNode.new(
          doc.find_significant_nodes_with_name(:binding, :post)
        ).transform do |meta_node|
          meta_node.nodes[0].before(StringDoc::Node.new("insert")); meta_node
        end

        @renderable = doc.deep_freeze
      end

      it "transforms on render" do
        expect(@renderable.render).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="utf-8">
            </head>

            <body>
              insert

              <article data-b="post" data-c="article">
                <h1 data-b="title" data-c="article">1 title goes here</h1>
              </article>

              <article data-b="post" data-c="article">
                <h1 data-b="title" data-c="article">2 title goes here</h1>
              </article>
            </body>
            </html>
          HTML
        )
      end
    end
  end

  describe "passing runtime context to a render" do
    before do
      local = self
      doc.find_significant_nodes_with_name(:binding, :post)[0].find_significant_nodes_with_name(:binding, :title)[0].transform do |node, context|
        local.instance_variable_set(:@context, context)
      end

      @renderable = doc.deep_freeze
    end

    before do
      @context = nil
    end

    it "passes" do
      expect {
        @renderable.render(context: :test)
      }.to change {
        @context
      }.from(nil).to(:test)
    end
  end
end
