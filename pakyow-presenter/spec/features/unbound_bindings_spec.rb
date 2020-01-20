RSpec.describe "unbound bindings" do
  include_context "app"

  context "value is bound to one binding but not the other" do
    let :app_def do
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
              <article data-b="post">
                <h1 data-b="title">foo</h1>
              </article>

              <script type="text/template" data-b="post">
                <article data-b="post">
                  <h1 data-b="title"></h1>
                  <p data-b="body"></p>
                </article>
              </script>
            </body>
          </html>
        HTML
      )
    end
  end

  context "nil is bound to a binding" do
    let :app_def do
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
              <script type="text/template" data-b="post">
                <article data-b="post">
                  <h1 data-b="title"></h1>
                  <p data-b="body"></p>
                </article>
              </script>
            </body>
          </html>
        HTML
      )
    end
  end

  context "binding is replaced with a node that is not a binding" do
    let :app_def do
      Proc.new do
        presenter "/unbound" do
          render :post do
            replace("foo")
          end
        end
      end
    end

    it "does not remove the replacement" do
      expect(call("/unbound")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              foo

              <script type="text/template" data-b="post">
                <article data-b="post">
                  <h1 data-b="title"></h1>
                  <p data-b="body"></p>
                </article>
              </script>
            </body>
          </html>
        HTML
      )
    end
  end
end
