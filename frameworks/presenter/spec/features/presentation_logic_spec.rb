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
          present :post do |post|
            use(post[:version])
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
          present :comment do |comment|
            use(comment[:version])
          end
        end
      end
    end

    it "presents" do
      expect(call("/presentation/logic/nested")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <div data-b="comment" data-v="two">
              two

              <h1 data-b="title">bar</h1>
            </div>

            <div data-b="comment" data-v="default">
              default

              <h1 data-b="title">baz</h1>
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

  context "logic defined for a channeled binding" do
    let :app_def do
      Proc.new do
        controller do
          get "/presentation/logic/channeled" do
            expose "posts:foo", [{ title: "foo", version: :two }, { title: "bar", version: :default }]
          end
        end

        presenter "/presentation/logic/channeled" do
          present "post:foo" do |post|
            use(post[:version])
          end
        end
      end
    end

    it "presents" do
      expect(call("/presentation/logic/channeled")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post:foo" data-v="two">
            channeled two

            <h1 data-b="title">foo</h1>
          </div>

          <div data-b="post:foo" data-v="default">
            channeled default

            <h1 data-b="title">bar</h1>
          </div>
        HTML
      )
    end
  end
end
