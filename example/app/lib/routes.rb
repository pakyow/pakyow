module Pakyow::Helpers
  def current_user
  end
end

Pakyow::App.router :default do
  presentable :current_user

  def post
    [{ body: "foo" }, { body: "bar" }]
  end

  default do
    presentable :post

    # render "/"
  end
end

Pakyow::App.view "/" do
  # view.scope(:post).apply([{ body: rand.to_s }, { body: rand.to_s }, { body: rand.to_s }])
  find(:post).present(post)
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
