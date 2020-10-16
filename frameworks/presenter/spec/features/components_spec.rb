RSpec.describe "rendering with backend components" do
  include_context "app"

  let :app_def do
    Proc.new do
      component :single do
        def perform
          expose :posts, [
            { title: "post 1" },
            { title: "post 2" },
            { title: "post 3" }
          ]
        end
      end
    end
  end

  it "renders once for each instance of the component" do
    expect(call("/components")[2]).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>default</title>
          </head>

          <body>
            <div data-ui="single">
          <div data-b="post">
            <h1 data-b="title">post 1</h1>
          </div><div data-b="post">
            <h1 data-b="title">post 2</h1>
          </div><div data-b="post">
            <h1 data-b="title">post 3</h1>
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

  context "component is used multiple times" do
    let :app_def do
      Proc.new do
        component :multiple do
          def perform
            expose :posts, [
              { title: "post #{$post_counter += 1}" },
              { title: "post #{$post_counter += 1}" },
              { title: "post #{$post_counter += 1}" }
            ]
          end
        end
      end
    end

    it "renders each instance of the component" do
      $post_counter = 0
      expect(call("/components/multiple")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-ui="multiple">
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

              <div data-ui="multiple">
                more posts:

                <div data-b="post">
                  <h1 data-b="title">post 4</h1>
                </div>

                <div data-b="post">
                  <h1 data-b="title">post 5</h1>
                </div>

                <div data-b="post">
                  <h1 data-b="title">post 6</h1>
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

  context "component is nested within another component" do
    let :app_def do
      Proc.new do
        component :parent do
          def perform
            expose :posts, [
              { title: "post 1", comments: [{ body: "post 1, comment 1"}] },
              { title: "post 2" },
              { title: "post 3", comments: [{ body: "post 3, comment 1"}, { body: "post 3, comment 2"}] }
            ]
          end
        end

        component :child do
          presenter do
            render node: -> { self } do
              attrs[:style][:color] = "red"
            end
          end
        end
      end
    end

    it "renders each component" do
      expect(call("/components/nested")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-ui="parent">
                <div data-b="post">
                  <h1 data-b="title">post 1</h1>

                  <div data-ui="child" style="color: red;">
                    <script type="text/template" data-b="comment">
                      <div data-b="comment">
                        <p data-b="body">
                          comment body here
                        </p>
                      </div>
                    </script>
                  </div>
                </div>

                <div data-b="post">
                  <h1 data-b="title">post 2</h1>

                  <div data-ui="child" style="color: red;">
                    <script type="text/template" data-b="comment">
                      <div data-b="comment">
                        <p data-b="body">
                          comment body here
                        </p>
                      </div>
                    </script>
                  </div>
                </div>

                <div data-b="post">
                  <h1 data-b="title">post 3</h1>

                  <div data-ui="child" style="color: red;">
                    <script type="text/template" data-b="comment">
                      <div data-b="comment">
                        <p data-b="body">
                          comment body here
                        </p>
                      </div>
                    </script>
                  </div>
                </div>

                <script type="text/template" data-b="post">
                  <div data-b="post">
                    <h1 data-b="title">
                      title goes here
                    </h1>

                    <div data-ui="child">
                      <div data-b="comment">
                        <p data-b="body">
                          comment body here
                        </p>
                      </div>
                    </div>
                  </div>
                </script>
              </div>
            </body>
          </html>
        HTML
      )
    end
  end

  context "main presenter removes the component" do
    let :app_def do
      Proc.new do
        presenter "/components" do
          render node: -> { components }, priority: :high do
            remove
          end
        end

        component :single do
          def perform
            expose :posts, [
              { title: "post 1" },
              { title: "post 2" },
              { title: "post 3" }
            ]
          end
        end
      end
    end

    it "does not render the component" do
      expect(call("/components")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>


            </body>
          </html>
        HTML
      )
    end
  end

  context "controller exposes a value" do
    let :app_def do
      Proc.new do
        controller "/components" do
          default do
            expose :posts, [
              { title: "controller post 1" },
              { title: "controller post 2" },
              { title: "controller post 3" }
            ]
          end
        end

        component :single do
          def perform
            # intentionally empty
          end
        end
      end
    end

    it "does not expose the value to the component" do
      expect(call("/components")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-ui="single">
            <script type="text/template" data-b="post"><div data-b="post">
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

  context "controller exposes a value and the component inherits values" do
    let :app_def do
      Proc.new do
        controller "/components" do
          default do
            expose :posts, [
              { title: "controller post 1" },
              { title: "controller post 2" },
              { title: "controller post 3" }
            ]
          end
        end

        component :single, inherit_values: true do
          def perform
            # intentionally empty
          end
        end
      end
    end

    it "exposes the value to the component" do
      expect(call("/components")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-ui="single">
            <div data-b="post">
              <h1 data-b="title">controller post 1</h1>
            </div><div data-b="post">
              <h1 data-b="title">controller post 2</h1>
            </div><div data-b="post">
              <h1 data-b="title">controller post 3</h1>
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

  context "controller exposes a value and the component inherit the specific value" do
    let :app_def do
      Proc.new do
        controller "/components" do
          default do
            expose :posts, [
              { title: "controller post 1" },
              { title: "controller post 2" },
              { title: "controller post 3" }
            ]
          end
        end

        component :single, inherit_values: [:posts] do
          def perform
            # intentionally empty
          end
        end
      end
    end

    it "exposes the value to the component" do
      expect(call("/components")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-ui="single">
            <div data-b="post">
              <h1 data-b="title">controller post 1</h1>
            </div><div data-b="post">
              <h1 data-b="title">controller post 2</h1>
            </div><div data-b="post">
              <h1 data-b="title">controller post 3</h1>
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

  context "controller and component expose a value for the same binding" do
    let :app_def do
      Proc.new do
        controller "/components" do
          default do
            expose :posts, [
              { title: "controller post 1" },
              { title: "controller post 2" },
              { title: "controller post 3" }
            ]
          end
        end

        component :single do
          def perform
            expose :posts, [
              { title: "component post 1" },
              { title: "component post 2" },
              { title: "component post 3" }
            ]
          end
        end
      end
    end

    it "uses the component value" do
      expect(call("/components")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-ui="single">
            <div data-b="post">
              <h1 data-b="title">component post 1</h1>
            </div><div data-b="post">
              <h1 data-b="title">component post 2</h1>
            </div><div data-b="post">
              <h1 data-b="title">component post 3</h1>
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

  context "controller exposes a system value" do
    let :app_def do
      Proc.new do
        controller "/components" do
          default do
            expose :__posts, [
              { title: "controller post 1" },
              { title: "controller post 2" },
              { title: "controller post 3" }
            ]
          end
        end

        component :single do
          def perform
            expose :posts, connection.get(:__posts)
          end
        end
      end
    end

    it "exposes the value to the component" do
      expect(call("/components")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-ui="single">
            <div data-b="post">
              <h1 data-b="title">controller post 1</h1>
            </div><div data-b="post">
              <h1 data-b="title">controller post 2</h1>
            </div><div data-b="post">
              <h1 data-b="title">controller post 3</h1>
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

  context "component defines a presenter" do
    let :app_def do
      Proc.new do
        component :single do
          presenter do
            render node: -> { self } do
              attrs[:style][:background] = "blue"
            end
          end
        end
      end
    end

    it "uses the defined presenter" do
      expect(call("/components")[2]).to eq_sans_whitespace(
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head>
              <title>default</title>
            </head>

            <body>
              <div data-ui="single" style="background: blue;">
                <script type="text/template" data-b="post"><div data-b="post">
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

  context "app is running in prototype mode" do
    let :mode do
      :prototype
    end

    it "does not call the component" do
      expect(call("/components")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-ui="single">
            <div data-b="post">
              <h1 data-b="title">
                title goes here
              </h1>
            </div>
          </div>
        HTML
      )
    end
  end

  context "component fails to render" do
    let :app_def do
      Proc.new do
        component :single do
          presenter do
            render node: -> { self } do
              fail
            end
          end
        end
      end
    end

    let :allow_request_failures do
      true
    end

    it "causes the request to fail" do
      call("/components")
      expect(connection.error).to be_instance_of(RuntimeError)
    end

    context "streaming renders are enabled" do
      let :app_def do
        Proc.new do
          configure :test do
            config.presenter.features.streaming = true
          end

          component :single do
            presenter do
              render node: -> { self } do
                fail
              end
            end
          end
        end
      end

      it "marks the component as having failed to render" do
        expect(call("/components")[2]).to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <div data-ui="single" class="render-failed"></div>
              </body>
            </html>
          HTML
        )
      end
    end
  end
end
