RSpec.describe "presenting a view that defines an anchor endpoint that is a binding prop" do
  include_context "app"

  it "does not set the href automatically" do
    expect(call("/presentation/endpoints/anchor/binding_prop")[2]).to include_sans_whitespace(
      <<~HTML
        <div data-b="post">
          <a data-b="title" data-e="posts_list">title</a>
        </div>
      HTML
    )
  end

  context "binding is bound to" do
    let :app_init do
      Proc.new do
        resource :posts, "/posts" do
          list do
            render "/presentation/endpoints/anchor/binding_prop"
          end
        end

        presenter "/presentation/endpoints/anchor/binding_prop" do
          render :post do
            present(title: "foo")
          end
        end
      end
    end

    it "sets the href" do
      expect(call("/presentation/endpoints/anchor/binding_prop")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="post">
            <a data-b="title" data-e="posts_list" href="/posts">foo</a>
          </div>
        HTML
      )
    end

    context "endpoint is current" do
      it "receives a current class" do
        expect(call("/posts")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="post">
              <a data-b="title" data-e="posts_list" href="/posts" class="ui-current">foo</a>
            </div>
          HTML
        )
      end
    end

    context "binder exists" do
      let :app_init do
        Proc.new do
          resource :posts, "/posts" do
            list do
              render "/presentation/endpoints/anchor/binding_prop"
            end
          end

          presenter "/presentation/endpoints/anchor/binding_prop" do
            render :post do
              present(title: "foo")
            end
          end

          binder :post do
            def title
              object[:title].to_s.reverse
            end
          end
        end
      end

      it "sets the endpoint href" do
        expect(call("/presentation/endpoints/anchor/binding_prop")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="post">
              <a data-b="title" data-e="posts_list" href="/posts">oof</a>
            </div>
          HTML
        )
      end

      context "binder sets the href" do
        let :app_init do
          Proc.new do
            resource :posts, "/posts" do
              list do
                render "/presentation/endpoints/anchor/binding_prop"
              end
            end

            presenter "/presentation/endpoints/anchor/binding_prop" do
              render :post do
                present(title: "foo")
              end
            end

            binder :post do
              def title
                part :content do
                  object[:title].to_s.reverse
                end

                part :href do
                  "overridden"
                end
              end
            end
          end
        end

        it "gives precedence to the endpoint" do
          expect(call("/presentation/endpoints/anchor/binding_prop")[2]).to include_sans_whitespace(
            <<~HTML
              <div data-b="post">
                <a data-b="title" data-e="posts_list" href="/posts">oof</a>
              </div>
            HTML
          )
        end
      end
    end
  end
end
