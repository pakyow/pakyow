RSpec.describe "attaching a transform that inserts a node after" do
  include_context "app"

  context "attached to binding" do
    describe "inserting after top level node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render :post do
              bind(title: "foo")
              after("after")
            end
          end
        end
      end

      it "replaces" do
        expect(call("/presentation/transforms")[2]).to eq_sans_whitespace(
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

                after

                <script type="text/template" data-b="post">
                  <div data-b="post">
                    <h1 data-b="title">
                      title goes here
                    </h1>
                  </div>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end

    describe "inserting after child node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render :post do
              bind(title: "foo")
              find(:title).after("after")
            end
          end
        end
      end

      it "replaces" do
        expect(call("/presentation/transforms")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <div data-b="post">
                  <h1 data-b="title">foo</h1>

                  after
                </div>

                <script type="text/template" data-b="post">
                  <div data-b="post">
                    <h1 data-b="title">
                      title goes here
                    </h1>
                  </div>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end
  end

  context "attached to node" do
    describe "inserting after top level node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render node: -> { find(:post).versions[0] } do
              bind(title: "foo")
              after("after")
            end
          end
        end
      end

      it "replaces" do
        expect(call("/presentation/transforms")[2]).to eq_sans_whitespace(
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

                after

                <script type="text/template" data-b="post">
                  <div data-b="post">
                    <h1 data-b="title">
                      title goes here
                    </h1>
                  </div>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end

    describe "inserting after child node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render node: -> { find(:post).versions[0] } do
              bind(title: "foo")
              find(:title).after("after")
            end
          end
        end
      end

      it "replaces" do
        expect(call("/presentation/transforms")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <div data-b="post">
                  <h1 data-b="title">foo</h1>

                  after
                </div>

                <script type="text/template" data-b="post">
                  <div data-b="post">
                    <h1 data-b="title">
                      title goes here
                    </h1>
                  </div>
                </script>
              </body>
            </html>
          HTML
        )
      end
    end
  end
end
