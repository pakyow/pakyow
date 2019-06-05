RSpec.describe "presenting with presentation logic for a binding" do
  include_context "app"

  context "logic defined for a binding" do
    let :app_def do
      Proc.new do
        controller do
          get "/presentation/logic" do
            expose :posts, [{ title: "foo", version: :two }, { title: "bar", version: :default }]
          end
        end

        presenter "/presentation/logic" do
          present :post do |view, post|
            view.use(post[:version])
          end
        end
      end
    end

    it "presents" do
      expect(call("/presentation/logic")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="two">
            two

            <h1 data-b="title">foo</h1>
          </div>

          <div data-b="post" data-v="default">
            default

            <h1 data-b="title">bar</h1>
          </div>
        HTML
      )
    end
  end

  context "logic defined for a nested binding" do
    let :app_def do
      Proc.new do
        controller do
          get "/presentation/logic/nested" do
            expose :posts, [{ title: "foo", comments: [{ title: "bar", version: :two }, { title: "baz", version: :default }]}]
          end
        end

        presenter "/presentation/logic/nested" do
          present :comment do |view, comment|
            view.use(comment[:version])
          end
        end
      end
    end

    it "presents" do
      expect(call("/presentation/logic/nested")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <script type="text/template" data-b="comment" data-v="default">
              <div data-b="comment" data-v="default">
                default

                <h1 data-b="title"></h1>
              </div>
            </script>

            <div data-b="comment" data-v="two">
              two

              <h1 data-b="title">bar</h1>
            </div>

            <div data-b="comment" data-v="default">
              default

              <h1 data-b="title">baz</h1>
            </div>

            <script type="text/template" data-b="comment" data-v="two">
              <div data-b="comment" data-v="two">
                two

                <h1 data-b="title"></h1>
              </div>
            </script>
          </div>
        HTML
      )
    end
  end

  context "logic defined for a channeled binding" do
    let :app_def do
      Proc.new do
        controller do
          get "/presentation/logic/channeled" do
            expose :posts, [{ title: "foo", version: :two }, { title: "bar", version: :default }], for: :foo
          end
        end

        presenter "/presentation/logic/channeled" do
          present :post, channel: :foo do |view, post|
            view.use(post[:version])
          end
        end
      end
    end

    it "presents" do
      expect(call("/presentation/logic/channeled")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post" data-v="two" data-c="foo">
            channeled two

            <h1 data-b="title">foo</h1>
          </div>

          <div data-b="post" data-v="default" data-c="foo">
            channeled default

            <h1 data-b="title">bar</h1>
          </div>
        HTML
      )
    end
  end


    # context "logic defined for a channeled binding" do
    #   let :view do
    #     Pakyow::Presenter::View.new(
    #       <<~HTML
    #         <div binding="post" version="default">
    #           default

    #           <h1 binding="title"></h1>
    #         </div>

    #         <div binding="post" version="two">
    #           two

    #           <h1 binding="title"></h1>
    #         </div>

    #         <div binding="post:foo" version="default">
    #           channeled default

    #           <h1 binding="title"></h1>
    #         </div>

    #         <div binding="post:foo" version="two">
    #           channeled two

    #           <h1 binding="title"></h1>
    #         </div>
    #       HTML
    #     )
    #   end

    #   before do
    #     presenter_class.version :post, channel: :foo do |view, post|
    #       view.use(post[:version])
    #     end
    #   end

    #   context "channeled binding is presented" do
    #     it "calls the versioning logic" do
    #       presenter.find(:post, channel: :foo).present(version: :two)
    #       expect(presenter.to_s).to include("channeled two")
    #     end
    #   end

    #   context "channeled binding is not presented" do
    #     it "does not call the versioning logic" do
    #       presenter.find(:post).bind(version: :two)
    #       expect(presenter.to_s).to_not include("channeled two")
    #       expect(presenter.to_s).to_not include("two")
    #     end
    #   end
    # end
  end
