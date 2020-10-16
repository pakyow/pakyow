RSpec.describe "presenting data with a nested form" do
  include_context "app"

  context "parent and child have the same prop" do
    let :app_def do
      Proc.new do
        presenter "/presentation/forms/nested" do
          render :post do
            present(body: "foo")
          end
        end
      end
    end

    it "presents the form correctly" do
      expect(call("/presentation/forms/nested")[2]).to include_sans_whitespace(
        <<~HTML
          <input type="text" data-b="body" name="comment[body]"></form>
        HTML
      )
    end
  end

  context "nested form is for a nested resource" do
    let :app_def do
      Proc.new do
        resource :posts, "/posts" do
          show do
            expose :post, { id: 1 }
            render "/presentation/forms/nested"
          end

          resource :comments, "/comments" do
            create do; end
          end
        end
      end
    end

    it "sets up the action" do
      expect(call("/posts/1")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="comment:form" action="/posts/1/comments" method="post">
        HTML
      )
    end

    context "form has an endpoint" do
      let :app_def do
        Proc.new do
          resource :posts, "/posts" do
            show do
              expose :post, { id: 1 }
              render "/presentation/forms/nested/endpoint"
            end

            resource :comments, "/comments" do
              create do; end
            end
          end
        end
      end

      it "sets up the action" do
        expect(call("/posts/1")[2]).to include_sans_whitespace(
          <<~HTML
            <form data-b="comment:form" data-e="posts_comments_create" action="/posts/1/comments" method="post">
          HTML
        )
      end

      context "form is a component" do
        let :app_def do
          Proc.new do
            component :form do
            end

            resource :posts, "/posts" do
              show do
                expose :post, { id: 1 }
                render "/presentation/forms/nested/endpoint/component"
              end

              resource :comments, "/comments" do
                create do; end
              end
            end
          end
        end

        it "sets up the action" do
          expect(call("/posts/1")[2]).to include_sans_whitespace(
            <<~HTML
              <form data-b="comment:form" data-e="posts_comments_create" data-ui="form" action="/posts/1/comments" method="post">
            HTML
          )
        end
      end
    end
  end
end
