RSpec.describe "automatically presenting exposures made from a controller" do
  include_context "app"

  let :app_init do
    Proc.new do
      controller :default do
        get "/exposure" do
          expose :post, { title: "foo" }
        end
      end
    end
  end

  it "finds and presents each exposure" do
    expect(call("/exposure")[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">foo</h1>\n</div><script type=\"text/template\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
  end

  context "exposure is plural" do
    let :app_init do
      Proc.new do
        controller :default do
          get "/exposure" do
            expose :posts, [{ title: "foo" }, { title: "bar" }]
          end
        end
      end
    end

    it "finds and presents to the singular version" do
      expect(call("/exposure")[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">foo</h1>\n</div><div data-b=\"post\">\n  <h1 data-b=\"title\">bar</h1>\n</div><script type=\"text/template\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
    end
  end

  context "exposure is channeled" do
    let :app_init do
      Proc.new do
        controller :default do
          get "/exposure/channeled" do
            expose :post, { title: "foo" }, for: :foo
            expose :post, { title: "bar" }, for: :bar
          end
        end
      end
    end

    it "finds and presents each channeled version" do
      expect(call("/exposure/channeled")[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\" data-c=\"foo\">\n  foo\n  <h1 data-b=\"title\">foo</h1>\n</div><script type=\"text/template\" data-b=\"post\" data-c=\"foo\"><div data-b=\"post\" data-c=\"foo\">\n  foo\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n<div data-b=\"post\" data-c=\"bar\">\n  bar\n  <h1 data-b=\"title\">bar</h1>\n</div><script type=\"text/template\" data-b=\"post\" data-c=\"bar\"><div data-b=\"post\" data-c=\"bar\">\n  bar\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
    end

    context "exposure matches part of the channel in the view" do
      let :app_init do
        Proc.new do
          controller :default do
            get "/exposure/channeled/partial" do
              expose :post, { title: "foo" }, for: :foo
              expose :post, { title: "bar" }, for: :bar
            end
          end
        end
      end

      it "finds and presents each channeled version" do
        expect(call("/exposure/channeled/partial")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <article data-b="post" data-c="article:foo">
                  foo

                  <h1 data-b="title" data-c="article">foo</h1>
                </article>

                <script type="text/template" data-b="post" data-c="article:foo">
                  <article data-b="post" data-c="article:foo">
                    foo

                    <h1 data-b="title" data-c="article">title goes here</h1>
                  </article>
                </script>

                <article data-b="post" data-c="article:bar">
                  bar

                  <h1 data-b="title" data-c="article">bar</h1>
                </article>

                <script type="text/template" data-b="post" data-c="article:bar">
                  <article data-b="post" data-c="article:bar">
                    bar

                    <h1 data-b="title" data-c="article">title goes here</h1>
                  </article>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end
  end

  context "exposure cannot be found" do
    let :app_init do
      Proc.new do
        controller :default do
          get "/exposure" do
            expose :post, { title: "foo" }
            expose :nonexistent, {}
          end
        end
      end
    end

    it "does not fail" do
      expect(call("/exposure")[2]).to eq_sans_whitespace("<!DOCTYPE html>\n<html>\n  <head>\n    <title>default</title>\n  </head>\n\n  <body>\n    <div data-b=\"post\">\n  <h1 data-b=\"title\">foo</h1>\n</div><script type=\"text/template\" data-b=\"post\"><div data-b=\"post\">\n  <h1 data-b=\"title\">title goes here</h1>\n</div></script>\n\n  </body>\n</html>\n")
    end
  end

  context "app presents to the view" do
    let :app_init do
      Proc.new do
        controller :default do
          get "/exposure" do
            expose :post, { title: "foo" }
          end
        end

        presenter "/exposure" do
          render :post do
            present(title: "bar")
          end
        end
      end
    end

    it "does not override the app" do
      expect(call("/exposure")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-b="post">
                <h1 data-b="title">bar</h1>
              </div>

              <script type="text/template" data-b="post">
                <div data-b="post">
                  <h1 data-b="title">title goes here</h1>
                </div>
              </script>
            </body>
          </html>
        HTML
      )
    end
  end

  context "view contains an empty version" do
    context "data is empty" do
      let :app_init do
        Proc.new do
          controller :default do
            get "/exposure/empty" do
              expose :posts, []
            end
          end
        end
      end

      it "presents the empty version" do
        expect(call("/exposure/empty")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <p data-b="post" data-v="empty">
                  nothing here
                </p>

                <script type="text/template" data-b="post" data-v="empty">
                  <p data-b="post" data-v="empty">
                    nothing here
                  </p>
                </script>

                <script type="text/template" data-b="post">
                  <div data-b="post">
                    <h1 data-b="title">title goes here</h1>
                  </div>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end

    context "data is not empty" do
      let :app_init do
        Proc.new do
          controller :default do
            get "/exposure/empty" do
              expose :posts, [{ title: "foo" }, { title: "bar" }, { title: "baz" }]
            end
          end
        end
      end

      it "presents the data" do
        expect(call("/exposure/empty")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <div data-b="post">
                  <h1 data-b="title">foo</h1>
                </div>

                <div data-b="post">
                  <h1 data-b="title">bar</h1>
                </div>

                <div data-b="post">
                  <h1 data-b="title">baz</h1>
                </div>

                <script type="text/template" data-b="post" data-v="empty">
                  <p data-b="post" data-v="empty">
                    nothing here
                  </p>
                </script>

                <script type="text/template" data-b="post">
                  <div data-b="post">
                    <h1 data-b="title">title goes here</h1>
                  </div>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end
  end

  context "view contains an empty version after the binding" do
    context "data is empty" do
      let :app_init do
        Proc.new do
          controller :default do
            get "/exposure/empty-last" do
              expose :posts, []
            end
          end
        end
      end

      it "presents the empty version" do
        expect(call("/exposure/empty-last")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <p data-b="post" data-v="empty">
                  nothing here
                </p>

                <script type="text/template" data-b="post">
                  <div data-b="post">
                    <h1 data-b="title">title goes here</h1>
                  </div>
                </script>

                <script type="text/template" data-b="post" data-v="empty">
                  <p data-b="post" data-v="empty">
                    nothing here
                  </p>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end

    context "data is not empty" do
      let :app_init do
        Proc.new do
          controller :default do
            get "/exposure/empty-last" do
              expose :posts, [{ title: "foo" }, { title: "bar" }, { title: "baz" }]
            end
          end
        end
      end

      it "presents the data" do
        expect(call("/exposure/empty-last")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <div data-b="post">
                  <h1 data-b="title">foo</h1>
                </div>

                <div data-b="post">
                  <h1 data-b="title">bar</h1>
                </div>

                <div data-b="post">
                  <h1 data-b="title">baz</h1>
                </div>

                <script type="text/template" data-b="post">
                  <div data-b="post">
                    <h1 data-b="title">title goes here</h1>
                  </div>
                </script>

                <script type="text/template" data-b="post" data-v="empty">
                  <p data-b="post" data-v="empty">
                    nothing here
                  </p>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end
  end
end
