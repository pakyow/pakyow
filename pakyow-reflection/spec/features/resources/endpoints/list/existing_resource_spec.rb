RSpec.describe "reflected resource list endpoint" do
  include_context "reflectable app"

  let :frontend_test_case do
    "endpoints/resource/list"
  end

  let :data do
    Pakyow.apps.first.data
  end

  before do
    data.posts.create(title: "foo", body: "foo body")
    data.posts.create(title: "bar", body: "bar body")
    data.posts.create(title: "baz", body: "baz body")
  end

  context "reflected action is not defined in the existing resource" do
    let :reflected_app_def do
      Proc.new do
        source :posts do
          attribute :title
          attribute :body
        end

        resource :posts, "/posts" do
          # intentionally empty
        end
      end
    end

    it "defines the reflected endpoint" do
      expect(call("/posts")[0]).to eq(200)
    end
  end

  context "endpoint is defined in the existing resource that matches the reflected endpoint" do
    context "existing endpoint exposes data" do
      let :reflected_app_def do
        Proc.new do
          source :posts do
            attribute :title
            attribute :body

            def reversed
              order {
                id.desc
              }
            end
          end

          resource :posts, "/posts" do
            list do
              expose :post, data.posts.reversed
            end
          end
        end
      end

      it "presents the data exposed by the existing endpoint" do
        expect(call("/posts")[2]).to include_sans_whitespace(
          <<~HTML
            <article data-b="post" data-c="article" data-id="3">
              <h1 data-b="title" data-c="article">baz</h1>
              <p data-b="body" data-c="article">baz body</p>
            </article>

            <article data-b="post" data-c="article" data-id="2">
              <h1 data-b="title" data-c="article">bar</h1>
              <p data-b="body" data-c="article">bar body</p>
            </article>

            <article data-b="post" data-c="article" data-id="1">
              <h1 data-b="title" data-c="article">foo</h1>
              <p data-b="body" data-c="article">foo body</p>
            </article>
          HTML
        )
      end
    end

    context "existing endpoint exposes data to a variation of the binding" do
      let :reflected_app_def do
        Proc.new do
          source :posts do
            attribute :title
            attribute :body

            def reversed
              order {
                id.desc
              }
            end
          end

          resource :posts, "/posts" do
            list do
              expose :posts, data.posts.reversed
            end
          end
        end
      end

      it "presents the data exposed by the existing endpoint" do
        expect(call("/posts")[2]).to include_sans_whitespace(
          <<~HTML
            <article data-b="post" data-c="article" data-id="3">
              <h1 data-b="title" data-c="article">baz</h1>
              <p data-b="body" data-c="article">baz body</p>
            </article>

            <article data-b="post" data-c="article" data-id="2">
              <h1 data-b="title" data-c="article">bar</h1>
              <p data-b="body" data-c="article">bar body</p>
            </article>

            <article data-b="post" data-c="article" data-id="1">
              <h1 data-b="title" data-c="article">foo</h1>
              <p data-b="body" data-c="article">foo body</p>
            </article>
          HTML
        )
      end
    end

    context "existing endpoint does not expose data" do
      let :reflected_app_def do
        local = self
        Proc.new do
          source :posts do
            attribute :title
            attribute :body

            def reversed
              order {
                id.desc
              }
            end
          end

          resource :posts, "/posts" do
            list do
              local.instance_variable_set(:@called, true)
            end
          end
        end
      end

      it "calls the route" do
        expect {
          call("/posts")
        }.to change {
          @called
        }.to(true)
      end

      it "presents the data exposed by the reflection" do
        expect(call("/posts")[2]).to include_sans_whitespace(
          <<~HTML
            <article data-b="post" data-c="article" data-id="1">
              <h1 data-b="title" data-c="article">foo</h1>
              <p data-b="body" data-c="article">foo body</p>
            </article>

            <article data-b="post" data-c="article" data-id="2">
              <h1 data-b="title" data-c="article">bar</h1>
              <p data-b="body" data-c="article">bar body</p>
            </article>

            <article data-b="post" data-c="article" data-id="3">
              <h1 data-b="title" data-c="article">baz</h1>
              <p data-b="body" data-c="article">baz body</p>
            </article>
          HTML
        )
      end
    end

    context "existing endpoint explicitly renders without exposing data" do
      let :reflected_app_def do
        local = self
        Proc.new do
          source :posts do
            attribute :title
            attribute :body

            def reversed
              order {
                id.desc
              }
            end
          end

          resource :posts, "/posts" do
            list do
              render "/posts"
            end
          end
        end
      end

      it "presents the data exposed by the reflection" do
        expect(call("/posts")[2]).to include_sans_whitespace(
          <<~HTML
            <article data-b="post" data-c="article" data-id="1">
              <h1 data-b="title" data-c="article">foo</h1>
              <p data-b="body" data-c="article">foo body</p>
            </article>

            <article data-b="post" data-c="article" data-id="2">
              <h1 data-b="title" data-c="article">bar</h1>
              <p data-b="body" data-c="article">bar body</p>
            </article>

            <article data-b="post" data-c="article" data-id="3">
              <h1 data-b="title" data-c="article">baz</h1>
              <p data-b="body" data-c="article">baz body</p>
            </article>
          HTML
        )
      end
    end
  end
end
