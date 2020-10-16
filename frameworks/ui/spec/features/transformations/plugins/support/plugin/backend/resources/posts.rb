resource :posts, "/posts" do
  disable_protection :csrf

  list do
    expose :posts, data.posts
  end

  get "/app" do
    expose :posts, data.posts
    render "/posts/app"
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
