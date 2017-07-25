module Pakyow::Helpers
  def current_user
  end
end

Pakyow::App.router :default do
  presentable :current_user

  default do
    presentable :post, [{ body: "foo" }, { body: "bar" }]
    presentable :show_posts do
      true
    end

    # render "/"
  end
end

Pakyow::App.view "/" do
  # view.scope(:post).apply([{ body: rand.to_s }, { body: rand.to_s }, { body: rand.to_s }])
  if show_posts
    find(:post).present(post)
  else
    find(:post).view.remove
  end
end

Pakyow::App.binder :post do
  def body
    part :content do
      object[:body].reverse
    end

    part :title do
      "woot"
    end
  end
end
