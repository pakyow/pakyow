RSpec.describe "attaching multiple components to the same node" do
  include_context "app"

  let :app_def do
    Proc.new do
      component :foo do
        def perform
          expose :posts, [
            { title: "post 1" },
            { title: "post 2" },
            { title: "post 3" }
          ]
        end
      end

      component :bar, inherit_values: true do
        presenter do
          render do
            perform_render(self)
          end

          def perform_render(view)
            view.prepend("bar")
          end
        end
      end
    end
  end

  it "invokes each component" do
    expect(call("/components/multiple_per_node")[2]).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>default</title>
          </head>

          <body>
            <div data-ui="foo; bar">
              bar

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
            </div>
          </body>
        </html>
      HTML
    )
  end
end
