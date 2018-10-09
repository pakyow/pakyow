RSpec.describe "forms with channeled bindings" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      resource :posts, "/presentation/forms/channeled/posts" do
        new do
          expose :post, { title: "foo" }, for: [:form, :foo]
          expose :post, { title: "bar" }, for: [:form, :bar]
        end

        create do
        end
      end
    }
  end

  it "sets up the endpoint for each form" do
    call("/presentation/forms/channeled/posts/new")[2].body.read.tap do |body|
      expect(body).to include('<form data-b="post" data-c="form:foo" action="/presentation/forms/channeled/posts" method="post">')
      expect(body).to include('<form data-b="post" data-c="form:bar" action="/presentation/forms/channeled/posts" method="post">')
    end
  end

  it "exposes values to the correct form" do
    call("/presentation/forms/channeled/posts/new")[2].body.read.tap do |body|
      expect(body).to include('<input type="text" data-b="title" class="foo" data-c="form" name="post[title]" value="foo">')
      expect(body).to include('<input type="text" data-b="title" class="bar" data-c="form" name="post[title]" value="bar">')
    end
  end

  it "embeds a form[binding] field with the channeled binding name" do
    call("/presentation/forms/channeled/posts/new")[2].body.read.tap do |body|
      expect(body).to include('<input type="hidden" name="form[binding]" value="post:form:foo">')
      expect(body).to include('<input type="hidden" name="form[binding]" value="post:form:bar">')
    end
  end

  context "form endpoint is contextual" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        resource :posts, "/posts" do
          resource :comments, "/comments" do
            new do
              render "/presentation/forms/channeled/contextual"
            end

            create do
            end
          end
        end

        controller do
          get "/presentation/forms/channeled/contextual" do
            expose :comment, { post_id: 123 }, for: [:form, :foo]
            expose :comment, { post_id: 321 }, for: [:form, :bar]
          end
        end
      }
    end

    it "sets the endpoint for each form when the required values are exposed through params" do
      call("/posts/1/comments/new")[2].body.read.tap do |body|
        expect(body).to include('<form data-b="comment" data-e="posts_comments_create" data-c="form:foo" action="/posts/1/comments" method="post">')
        expect(body).to include('<form data-b="comment" data-e="posts_comments_create" data-c="form:bar" action="/posts/1/comments" method="post">')
      end
    end

    it "sets the endpoint for each form when the object exposes the required values" do
      call("/presentation/forms/channeled/contextual")[2].body.read.tap do |body|
        expect(body).to include('<form data-b="comment" data-e="posts_comments_create" data-c="form:foo" action="/posts/123/comments" method="post">')
        expect(body).to include('<form data-b="comment" data-e="posts_comments_create" data-c="form:bar" action="/posts/321/comments" method="post">')
      end
    end
  end
end
