RSpec.describe "attaching transforms to a presenter" do
  include_context "app"

  context "render is attached to the view as a whole" do
    let :app_def do
      Proc.new do
        presenter "/presentation/transforms" do
          render do
            find(:post).bind(title: "test")
          end
        end
      end
    end

    it "renders correctly" do
      expect(call("/presentation/transforms")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post"><h1 data-b="title">test</h1></div>
        HTML
      )
    end
  end

  context "render is attached to node block that returns a versioned view" do
    let :app_def do
      local = self
      Proc.new do
        presenter "/presentation/transforms" do
          render node: -> { find(:post) } do
            local.instance_variable_set(:@called, true)
            local.instance_variable_set(:@context, self)
          end
        end
      end
    end

    before do
      @called = false
    end

    it "calls during rendering" do
      expect {
        call("/presentation/transforms")
      }.to change {
        @called
      }.from(false).to(true)
    end

    it "calls in context of the presenter" do
      call("/presentation/transforms")
      expect(@context.class.ancestors).to include(Test::Presenter)
    end
  end

  context "render is attached to a node block that returns a view" do
    let :app_def do
      Proc.new do
        presenter "/presentation/transforms" do
          render node: -> { find(:post) } do
            bind(title: "test")
          end
        end
      end
    end

    it "renders correctly" do
      expect(call("/presentation/transforms")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post"><h1 data-b="title">test</h1></div>
        HTML
      )
    end
  end

  context "render is attached to a node block that returns another object" do
    let :app_def do
      Proc.new do
        presenter "/presentation/transforms" do
          render node: -> { :foo } do
            bind(title: "test")
          end
        end
      end
    end

    it "ignores the render" do
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

  context "render is attached to a binding" do
    let :app_def do
      local = self
      Proc.new do
        presenter "/presentation/transforms" do
          render :post do
            local.instance_variable_set(:@calls, local.instance_variable_get(:@calls) + 1)
          end
        end
      end
    end

    before do
      @calls = 0
    end

    it "attaches to the correct binding" do
      expect {
        call("/presentation/transforms")
      }.to change { @calls }.from(0).to(1)
    end
  end

  context "render is attached to a channeled binding" do
    let :app_def do
      local = self
      Proc.new do
        presenter "/presentation/transforms/channeled" do
          render "post:bar" do
            local.instance_variable_set(:@calls, local.instance_variable_get(:@calls) + 1)
          end
        end
      end
    end

    before do
      @calls = 0
    end

    it "attaches to the correct binding" do
      expect {
        call("/presentation/transforms/channeled")
      }.to change { @calls }.from(0).to(1)
    end
  end

  context "render fails" do
    let :app_def do
      Proc.new do
        presenter "/presentation/transforms/channeled" do
          render "post:foo" do
            fail
          end
        end
      end
    end

    let :allow_request_failures do
      true
    end

    it "causes the request to fail" do
      call("/presentation/transforms/channeled")
      expect(connection.error).to be_instance_of(RuntimeError)
    end

    context "streaming renders are enabled" do
      let :app_def do
        Proc.new do
          configure :test do
            config.presenter.features.streaming = true
          end

          presenter "/presentation/transforms/channeled" do
            render "post:foo" do
              fail
            end

            render "post:bar" do
              bind(title: "test")
            end
          end
        end
      end

      it "removes the node content, adds an error class, and continues rendering" do
        expect(call("/presentation/transforms/channeled")[2]). to eq_sans_whitespace(
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <title>default</title>
              </head>

              <body>
                <div data-b="post:foo" class="render-failed"></div>

                <script type="text/template" data-b="post:foo">
                  <div data-b="post:foo">
                    <h1 data-b="title">
                      title goes here
                    </h1>
                  </div>
                </script>

                <div data-b="post:bar">
                  <h1 data-b="title">test</h1>
                </div>

                <script type="text/template" data-b="post:bar">
                  <div data-b="post:bar">
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

  context "multiple renders attached to the same node" do
    let :app_def do
      Proc.new do
        presenter "/presentation/transforms" do
          render node: -> { find(:post) } do
            bind(title: "test")
          end

          render node: -> { find(:post) } do
            attributes[:class] << "test"
          end
        end
      end
    end

    it "renders correctly" do
      expect(call("/presentation/transforms")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" class="test"><h1 data-b="title">test</h1></div>
        HTML
      )
    end
  end

  describe "unsupported render options" do
    context "argument for node is not a proc" do
      it "fails" do
        expect {
          Class.new(Pakyow::Presenter::Presenter) do
            render node: :test do; end
          end
        }.to raise_error(ArgumentError) do |error|
          expect(error.message).to eq("Expected `Symbol' to be a proc")
        end
      end
    end
  end

  context "render attached to a node within a channeled binding" do
    let :app_def do
      Proc.new do
        presenter "/presentation/transforms/nested-within-channeled" do
          render "post:foo" do
            object.set_label(:bound, true)
          end

          render "post:foo", "comment" do
            bind(title: "test")
          end
        end
      end
    end

    it "renders correctly" do
      expect(call("/presentation/transforms/nested-within-channeled")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post:foo"><div data-b="comment"><h1 data-b="title">test</h1></div>
        HTML
      )
    end
  end

  context "render defined for a top-level and nested binding" do
    let :app_def do
      Proc.new do
        presenter "/presentation/logic/nested" do
          render :post do
            find(:comment).attrs[:style][:background] = "blue"

            present(
              comments: [
                { title: "cone" },
                { title: "ctwo"}
              ]
            )
          end

          render :post, :comment do
            attrs[:style][:color] = "red"
          end
        end
      end
    end

    it "renders" do
      expect(call("/presentation/logic/nested")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <div data-b="comment" data-v="default" style="background: blue; color: red;">
              default

              <h1 data-b="title">cone</h1>
            </div>

            <div data-b="comment" data-v="default" style="background: blue; color: red;">
              default

              <h1 data-b="title">ctwo</h1>
            </div>

            <script type="text/template" data-b="comment" data-v="default">
              <div data-b="comment" data-v="default">
                default

                <h1 data-b="title"></h1>
              </div>
            </script>

            <script type="text/template" data-b="comment" data-v="two">
              <div data-b="comment" data-v="two">
                two

                <h1 data-b="title"></h1>
              </div>
            </script>
          </div>

          <script type="text/template" data-b="post">
            <div data-b="post">
              <div data-b="comment" data-v="default">
                default

                <h1 data-b="title"></h1>
              </div>

              <div data-b="comment" data-v="two">
                two

                <h1 data-b="title"></h1>
              </div>
            </div>
          </script>
        HTML
      )
    end
  end
end
