RSpec.describe "forms with channeled bindings" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :posts, "/presentation/forms/channeled/posts" do
        new do
          expose "post:form:foo", { title: "foo" }
          expose "post:form:bar", { title: "bar" }
        end

        create do
        end
      end
    end
  end

  it "sets up the endpoint for each form" do
    call("/presentation/forms/channeled/posts/new")[2].tap do |body|
      expect(body).to include('<form data-b="post:form:foo" action="/presentation/forms/channeled/posts" method="post">')
      expect(body).to include('<form data-b="post:form:bar" action="/presentation/forms/channeled/posts" method="post">')
    end
  end

  it "exposes values to the correct form" do
    call("/presentation/forms/channeled/posts/new")[2].tap do |body|
      expect(body).to include('<input type="text" data-b="title" class="foo" name="post[title]" value="foo">')
      expect(body).to include('<input type="text" data-b="title" class="bar" name="post[title]" value="bar">')
    end
  end

  context "form endpoint is contextual" do
    let :app_init do
      Proc.new do
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
            expose "comment:form:foo", { post_id: 123 }
            expose "comment:form:bar", { post_id: 321 }
          end
        end
      end
    end

    it "sets the endpoint for each form when the required values are exposed through params" do
      call("/posts/1/comments/new")[2].tap do |body|
        expect(body).to include('<form data-b="comment:form:foo" data-e="posts_comments_create" action="/posts/1/comments" method="post">')
        expect(body).to include('<form data-b="comment:form:bar" data-e="posts_comments_create" action="/posts/1/comments" method="post">')
      end
    end

    it "sets the endpoint for each form when the object exposes the required values" do
      call("/presentation/forms/channeled/contextual")[2].tap do |body|
        expect(body).to include('<form data-b="comment:form:foo" data-e="posts_comments_create" action="/posts/123/comments" method="post">')
        expect(body).to include('<form data-b="comment:form:bar" data-e="posts_comments_create" action="/posts/321/comments" method="post">')
      end
    end
  end
end
