RSpec.describe "unbound bindings" do
  include_context "app"

  context "value is bound to one binding but not the other" do
    let :app_init do
      Proc.new do
        presenter "/unbound" do
          render :post do
            bind(title: "foo")
          end
        end
      end
    end

    it "removes the unbound binding" do
      expect(call("/unbound")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <article data-b="post" data-c="article">
                <h1 data-b="title" data-c="article">foo</h1>
              </article>

              <script type="text/template" data-b="post" data-c="article">
                <article data-b="post" data-c="article">
                  <h1 data-b="title" data-c="article"></h1>
                  <p data-b="body" data-c="article"></p>
                </article>
              </script>
            </body>
          </html>
        HTML
      )
    end
  end

  context "nil is bound to a binding" do
    let :app_init do
      Proc.new do
        presenter "/unbound" do
          render :post do
            bind(nil)
          end
        end
      end
    end

    it "removes the unbound binding" do
      expect(call("/unbound")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <script type="text/template" data-b="post" data-c="article">
                <article data-b="post" data-c="article">
                  <h1 data-b="title" data-c="article"></h1>
                  <p data-b="body" data-c="article"></p>
                </article>
              </script>
            </body>
          </html>
        HTML
      )
    end
  end
end
