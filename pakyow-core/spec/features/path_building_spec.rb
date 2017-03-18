RSpec.describe "path building" do
  include_context "testable app"
  using Pakyow::Support::DeepDup

  def define
    Pakyow::App.define do
      router do
        def other_params
          Hash[params.map { |k, v|
            next if k == "name"
            [k.to_sym, v]
          }.reject(&:nil?)]
        end

        get "/path/:name" do
          send path(params[:name], **other_params) || ""
        end
      end

      router :main do
        default
        get :foo, "/foo"
        get :bar, "/bar/:id"

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

      resource :post, "/posts" do
        list

        resource :comment, "/comments" do
          list
        end
      end
    end
  end

  it "builds path to a default route" do
    expect(call("/path/main_default")[2].body.read).to eq("/")
  end

  it "builds path to a named route" do
    expect(call("/path/main_foo")[2].body.read).to eq("/foo")
  end

  it "builds path to a named route with params" do
    expect(call("/path/main_bar", params: { id: "123" })[2].body.read).to eq("/bar/123")
  end

  it "builds path to a grouped route" do
    expect(call("/path/main_grouped_default")[2].body.read).to eq("/")
  end

  it "builds path to a namespaced route" do
    expect(call("/path/main_namespaced_default")[2].body.read).to eq("/ns")
  end

  it "builds path to a deeply nested route" do
    expect(call("/path/main_namespaced_deep_default")[2].body.read).to eq("/ns/deep")
  end

  it "builds path to a resource route" do
    expect(call("/path/post_list")[2].body.read).to eq("/posts")
  end

  it "builds path to a nested resource route" do
    expect(call("/path/post_comment_list", params: { post_id: "123" })[2].body.read).to eq("/posts/123/comments")
  end
end
