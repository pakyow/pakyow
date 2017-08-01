# frozen_string_literal: true

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

    # # TODO: this should return a query context that wraps a value; never interact directly with the objects
    # user = model.user.create(name: "foo")

    # # this is how a query would be setup and eventually called before passed as a presentable
    # model.user[1]

    # logger.info "hello user[#{user.id}]"

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
