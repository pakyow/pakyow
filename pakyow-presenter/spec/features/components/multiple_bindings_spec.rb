RSpec.describe "rendering backend components alongside other bindings" do
  include_context "app"

  let :app_def do
    Proc.new do
      controller "/components/multiple_bindings" do
        default do
          expose :posts, [
            { title: "post 1" },
            { title: "post 2" },
            { title: "post 3" }
          ], for: :all
        end
      end

      component :recent do
        def perform
          expose :posts, [
            { title: "recent post" }
          ]
        end
      end
    end
  end

  it "renders all the bindings properly" do
    expect(call("/components/multiple_bindings")[2]).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>default</title>
          </head>

          <body>
            <div data-b="post" data-c="all">
          <h1 data-b="title">post 1</h1>


        </div><div data-b="post" data-c="all">
          <h1 data-b="title">post 2</h1>


        </div><div data-b="post" data-c="all">
          <h1 data-b="title">post 3</h1>


        </div><script type="text/template" data-b="post" data-c="all"><div data-b="post" data-c="all">
          <h1 data-b="title">
            title goes here
          </h1>

          <p data-b="body">
            body goes here
          </p>
        </div></script>

        <div data-ui="recent">
          <div data-b="post">
            <h1 data-b="title">recent post</h1>
          </div><script type="text/template" data-b="post"><div data-b="post">
            <h1 data-b="title">
              title goes here
            </h1>
          </div></script>
        </div>

          </body>
        </html>
      HTML
    )
  end
end
