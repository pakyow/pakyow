RSpec.describe "rending components whose path is affected by the build step" do
  include_context "app"

  let :app_def do
    Proc.new do
      configure :test do
        config.presenter.componentize = true
      end

      component :bar do
      end

      component :baz do
        def perform
          expose :posts, [
            { title: "post 1" },
            { title: "post 2" },
            { title: "post 3" }
          ]
        end
      end

      component :qux do
        presenter do
          render do
            self.html = "replaced"
          end
        end
      end
    end
  end

  it "renders correctly" do
    expect(call("/components/modes")[2]).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html data-ui="navigable">
          <head>
            <title>default</title>
          </head>

          <body>
            <div data-ui="bar">
              foo

              <div data-ui="baz">
                bar posts:

                <div data-b="post">
                  <h1 data-b="title">post 1</h1>
                </div>

                <div data-b="post">
                  <h1 data-b="title">post 2</h1>
                </div>

                <div data-b="post">
                  <h1 data-b="title">post 3</h1>
                </div>

                <script type="text/template" data-b="post">
                  <div data-b="post">
                    <h1 data-b="title">
                      title goes here
                    </h1>
                  </div>
                </script>

                <div data-ui="qux">
                  replaced
                </div>
              </div>
            </div>
          </body>
        </html>
      HTML
    )
  end
end
