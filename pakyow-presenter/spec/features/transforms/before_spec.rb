RSpec.describe "attaching a transform that inserts a node before" do
  include_context "app"

  context "attached to binding" do
    describe "inserting before top level node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render :post do
              bind(title: "foo")
              before("before")
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
                before

                <div data-b="post">
                  <h1 data-b="title">foo</h1>
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

    describe "inserting before child node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render :post do
              bind(title: "foo")
              find(:title).before("before")
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
                  before

                  <h1 data-b="title">foo</h1>
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
    describe "inserting before top level node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render node: -> { find(:post).versions[0] } do
              puts "!!!!!!!!!!!!!"
              bind(title: "foo")
              before("before")
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
                before

                <div data-b="post">
                  <h1 data-b="title">foo</h1>
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

    describe "inserting before child node" do
      let :app_init do
        Proc.new do
          presenter "/presentation/transforms" do
            render node: -> { find(:post).versions[0] } do
              bind(title: "foo")
              find(:title).before("before")
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
                  before

                  <h1 data-b="title">foo</h1>
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
