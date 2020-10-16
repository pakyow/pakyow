RSpec.describe "attaching a transform that removes a node" do
  include_context "app"

  context "attached to binding" do
    describe "removing top level node" do
      let :app_def do
        Proc.new do
          presenter "/presentation/transforms" do
            render :post do
              remove
            end
          end
        end
      end

      it "removes" do
        expect(call("/presentation/transforms")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
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

    describe "removing child node" do
      let :app_def do
        Proc.new do
          presenter "/presentation/transforms" do
            render :post do
              bind(title: "foo")
              find(:title).remove
            end
          end
        end
      end

      it "removes" do
        expect(call("/presentation/transforms")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <div data-b="post"></div>

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
    describe "removing top level node" do
      let :app_def do
        Proc.new do
          presenter "/presentation/transforms" do
            render node: -> { find(:post) } do
              remove
            end
          end
        end
      end

      it "removes" do
        expect(call("/presentation/transforms")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
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

    describe "removing child node" do
      let :app_def do
        Proc.new do
          presenter "/presentation/transforms" do
            render node: -> { find(:post) } do
              bind(title: "foo")
              find(:title).remove
            end
          end
        end
      end

      it "removes" do
        expect(call("/presentation/transforms")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <div data-b="post"></div>

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
