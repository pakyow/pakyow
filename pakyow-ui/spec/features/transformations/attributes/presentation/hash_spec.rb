RSpec.describe "modifying hash attributes during presentation" do
  include_context "testable app"
  include_context "websocket intercept"

  context "setting" do
    let :app_definition do
      Proc.new do
        instance_exec(&$ui_app_boilerplate)

        resources :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts do
          primary_id
        end

        presenter "/attributes/posts" do
          if posts.count > 0
            find(:post).present(posts) do |post_view, post|
              post_view.attrs[:style] = { color: "red" }
            end
          end
        end
      end
    end

    it "transforms" do
      transformations = save_ui_case("attributes_hash_set_presentation", path: "/posts") do
        call("/posts", method: :post)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["present",[[{"id":1}]],[[["attrs",[],[],[["[]=",["style",{"color":"red"}],[],[]]]]]],[]]]]]'
      )
    end
  end

  context "changing a value" do
    let :app_definition do
      Proc.new do
        instance_exec(&$ui_app_boilerplate)

        resources :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts do
          primary_id
        end

        presenter "/attributes/posts" do
          if posts.count > 0
            find(:post).present(posts) do |post_view, post|
              post_view.attrs[:style][:color] = "red"
            end
          end
        end
      end
    end

    it "transforms" do
      transformations = save_ui_case("attributes_hash_change_key_presentation", path: "/posts") do
        call("/posts", method: :post)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["present",[[{"id":1}]],[[["attrs",[],[],[["[]",["style"],[],[["[]=",["color","red"],[],[]]]]]]]],[]]]]]'
      )
    end
  end

  context "deleting a value" do
    let :app_definition do
      Proc.new do
        instance_exec(&$ui_app_boilerplate)

        resources :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts do
          primary_id
        end

        presenter "/attributes/posts" do
          if posts.count > 0
            find(:post).present(posts) do |post_view, post|
              post_view.attrs[:style].delete(:background)
            end
          end
        end
      end
    end

    it "transforms" do
      transformations = save_ui_case("attributes_hash_delete_key_presentation", path: "/posts") do
        call("/posts", method: :post)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["present",[[{"id":1}]],[[["attrs",[],[],[["[]",["style"],[],[["delete",["background"],[],[]]]]]]]],[]]]]]'
      )
    end
  end

  context "clearing" do
    let :app_definition do
      Proc.new do
        instance_exec(&$ui_app_boilerplate)

        resources :posts, "/posts" do
          disable_protection :csrf

          list do
            expose :posts, data.posts
            render "/attributes/posts"
          end

          create do
            data.posts.create; halt
          end
        end

        source :posts do
          primary_id
        end

        presenter "/attributes/posts" do
          if posts.count > 0
            find(:post).present(posts) do |post_view, post|
              post_view.attrs[:style].clear
            end
          end
        end
      end
    end

    it "transforms" do
      transformations = save_ui_case("attributes_hash_clear_presentation", path: "/posts") do
        call("/posts", method: :post)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["present",[[{"id":1}]],[[["attrs",[],[],[["[]",["style"],[],[["clear",[],[],[]]]]]]]],[]]]]]'
      )
    end
  end
end
