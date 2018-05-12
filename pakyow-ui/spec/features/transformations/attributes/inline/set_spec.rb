RSpec.describe "modifying set attributes" do
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
            find(:post).attrs[:class] = [:foo, :bar]

            # if we don't set this, the view won't quite match
            find(:post).attrs[:style] = {}
          end
        end
      end
    end

    it "transforms" do
      transformations = save_ui_case("attributes_set_set", path: "/posts") do
        call("/posts", method: :post)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["attrs",[],[],[["[]=",["class",["foo","bar"]],[],[]]]]]],["find",["post"],[],[["attrs",[],[],[["[]=",["style",{}],[],[]]]]]]]'
      )
    end
  end

  context "adding a value with <<" do
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
            find(:post).attrs[:class] << :foo

            # if we don't set this, the view won't quite match
            find(:post).attrs[:style] = {}
          end
        end
      end
    end

    it "transforms" do
      transformations = save_ui_case("attributes_set_shovel", path: "/posts") do
        call("/posts", method: :post)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["attrs",[],[],[["[]",["class"],[],[["<<",["foo"],[],[]]]]]]]],["find",["post"],[],[["attrs",[],[],[["[]=",["style",{}],[],[]]]]]]]'
      )
    end
  end

  context "adding a value with add" do
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
            find(:post).attrs[:class].add(:foo)

            # if we don't set this, the view won't quite match
            find(:post).attrs[:style] = {}
          end
        end
      end
    end

    it "transforms" do
      transformations = save_ui_case("attributes_set_add", path: "/posts") do
        call("/posts", method: :post)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["attrs",[],[],[["[]",["class"],[],[["add",["foo"],[],[]]]]]]]],["find",["post"],[],[["attrs",[],[],[["[]=",["style",{}],[],[]]]]]]]'
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
            find(:post).attrs[:class].delete(:one)

            # if we don't set this, the view won't quite match
            find(:post).attrs[:style] = {}
          end
        end
      end
    end

    it "transforms" do
      transformations = save_ui_case("attributes_set_delete", path: "/posts") do
        call("/posts", method: :post)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["attrs",[],[],[["[]",["class"],[],[["delete",["one"],[],[]]]]]]]],["find",["post"],[],[["attrs",[],[],[["[]=",["style",{}],[],[]]]]]]]'
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
            find(:post).attrs[:class].clear

            # if we don't set this, the view won't quite match
            find(:post).attrs[:style] = {}
          end
        end
      end
    end

    it "transforms" do
      transformations = save_ui_case("attributes_set_clear", path: "/posts") do
        call("/posts", method: :post)
      end

      expect(transformations[0][:calls].to_json).to eq(
        '[["find",["post"],[],[["attrs",[],[],[["[]",["class"],[],[["clear",[],[],[]]]]]]]],["find",["post"],[],[["attrs",[],[],[["[]=",["style",{}],[],[]]]]]]]'
      )
    end
  end
end
