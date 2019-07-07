RSpec.describe "path building" do
  include_context "app"
  using Pakyow::Support::DeepDup

  let :app_init do
    Proc.new {
      controller do
        def other_params
          Hash[params.map { |k, v|
            next if k == "name"
            [k.to_sym, v]
          }.reject(&:nil?)]
        end

        get "/path/:name" do
          send path(params[:name], other_params) || ""
        end
      end

      controller :main do
        default
        get :foo, "/foo"
        get :bar, "/bar/:id"
        get :slug, "/#:slug"

        namespace :internal, "/internal" do
          get :static, "#foo"
          get :params, "#:id"
        end

        group :grouped do
          default
        end

        namespace :namespaced, "/ns" do
          default

          namespace :deep, "/deep" do
            default
          end
        end
      end

      resource :posts, "/posts" do
        list

        resource :comments, "/comments" do
          list
        end

        collection do
          get :meta, "/meta"
        end
      end

      controller do
        get :unnamed, "/unnamed"
      end
    }
  end

  it "returns nil when no path found" do
    expect(call("/path/missing")[2]).to eq("")
  end

  it "builds path to a default route" do
    expect(call("/path/main_default")[2]).to eq("/")
  end

  it "builds path to a named route" do
    expect(call("/path/main_foo")[2]).to eq("/foo")
  end

  it "builds path to a named route with params" do
    expect(call("/path/main_bar", params: { id: "123" })[2]).to eq("/bar/123")
  end

  it "builds path to a grouped route" do
    expect(call("/path/main_grouped_default")[2]).to eq("/")
  end

  it "builds path to a namespaced route" do
    expect(call("/path/main_namespaced_default")[2]).to eq("/ns")
  end

  it "builds path to a deeply nested route" do
    expect(call("/path/main_namespaced_deep_default")[2]).to eq("/ns/deep")
  end

  it "builds path to a resource route" do
    expect(call("/path/posts_list")[2]).to eq("/posts")
  end

  it "builds path to a nested resource route" do
    expect(call("/path/posts_comments_list", params: { post_id: "123" })[2]).to eq("/posts/123/comments")
  end

  it "builds path to a named internal route" do
    expect(call("/path/main_internal_static")[2]).to eq("/internal#foo")
  end

  it "builds path to a named internal route with params" do
    expect(call("/path/main_internal_params", params: { id: "123" })[2]).to eq("/internal#123")
  end

  it "builds path to a collection route within a resource" do
    expect(call("/path/posts_meta", params: { id: "123" })[2]).to eq("/posts/meta")
  end

  it "builds path to a route within an unnamed controller" do
    expect(call("/path/unnamed")[2]).to eq("/unnamed")
  end

  it "builds path to a route to a route with a hash" do
    expect(call("/path/main_slug", params: { slug: "foo" })[2]).to eq("#foo")
  end
end
