RSpec.describe "attaching a transform that replaces a node" do
  include_context "app"

  context "attached to binding" do
    describe "replacing top level node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render :post do
              replace("replaced")
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
                replaced

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

    describe "replacing child node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render :post do
              bind(title: "foo")
              find(:title).replace("replaced")
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
                <div data-b="post">replaced</div>

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
    describe "replacing top level node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render node: -> { find(:post).versions[0] } do
              replace("replaced")
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
                replaced

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

    describe "replacing child node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render node: -> { find(:post).versions[0] } do
              bind(title: "foo")
              find(:title).replace("replaced")
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
                <div data-b="post">replaced</div>

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
