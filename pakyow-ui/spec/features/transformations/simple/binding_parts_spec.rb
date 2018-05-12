RSpec.describe "presenting an object with binding parts defined in a binder" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render "/simple/posts"
        end

        create do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.create(params[:post]); halt
        end
      end

      source :posts do
        primary_id
        attribute :title
      end

      binder :post do
        def title
          part :content do
            object[:title].to_s.reverse
          end

          part :style do
            { color: "red" }
          end

          part :class do
            [:fooclass]
          end

          part :title do
            object[:title]
          end

          part :selected do
            true
          end
        end
      end

      presenter "/simple/posts" do
        find(:post).present(posts)
      end
    end
  end

  it "transforms" do
    transformations = save_ui_case("binder_parts", path: "/posts") do
      call("/posts", method: :post, params: { post: { title: "foo" } })
    end

    expect(transformations[0][:calls].to_json).to eq(
      '[["find",["post"],[],[["present",[[{"id":1,"title":{"content":"oof","style":{"color":"red"},"class":["fooclass"],"title":"foo","selected":true}}]],[],[]]]]]'
    )
  end
end
