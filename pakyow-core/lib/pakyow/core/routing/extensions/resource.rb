require "pakyow/core/routing/extension"

module Pakyow
  module Routing
    module Extension
      # An extension for defining RESTful Resources. For example:
      #
      #   Pakyow::App.router do
      #     resource :post, "/posts" do
      #       list do
      #         # list the posts
      #       end
      #     end
      #   end
      #
      # +Resource+ is available in all routers by default.
      #
      # = Supported Actions
      #
      # These actions are supported:
      #
      # - +list+ -- +GET /+
      # - +new+ -- +GET /new+
      # - +create+ -- +POST /+
      # - +edit+ -- +GET /:resource_id/edit+
      # - +update+ -- +PATCH /:resource_id+
      # - +replace+ -- +PUT /:resource_id+
      # - +remove+ -- +DELETE /:resource_id+
      # - +show+ -- +GET /:resource_id+
      #
      # = Nested Resources
      #
      # Resources can be nested. For example:
      #
      #   Pakyow::App.router do
      #     resource :post, "/posts" do
      #       resource :comment, "/comments" do
      #         list do
      #           # available at GET /posts/:post_id/comments
      #         end
      #       end
      #     end
      #   end
      #
      # = Collection Routes
      #
      # Routes can be defined for the collection. For example:
      #
      #   Pakyow::App.router do
      #     resource :post, "/posts" do
      #       collection do
      #         get "/foo" do
      #           # available at GET /posts/foo
      #         end
      #       end
      #     end
      #   end
      #
      # = Member Routes
      #
      # Routes can be defined as members. For example:
      #
      #   Pakyow::App.router do
      #     resource :post, "/posts" do
      #       member do
      #         get "/foo" do
      #           # available at GET /posts/:post_id/foo
      #         end
      #       end
      #     end
      #   end
      #
      # @api public
      module Resource
        extend Extension

        template :resource do
          resource_id = ":#{@router.name}_id"

          # TODO: hook this back up for #show
          # view_path = nested_path.gsub(/:[^\/]+/, '').split('/').reject { |p| p.empty? }.join('/')
          # fn :reset_view_path do
          #   begin
          #     presenter.path = File.join(view_path, 'show') if @presenter
          #   rescue Presenter::MissingView
          #   end
          # end

          get :list, "/"
          get :new,  "/new"
          post :create, "/"
          get :edit, "/#{resource_id}/edit"
          patch :update, "/#{resource_id}"
          put :replace, "/#{resource_id}"
          delete :remove, "/#{resource_id}"
          get :show, "/#{resource_id}"

          # TODO: do these
          # group :collection
          # namespace :member, resource_id

          set_nested_path File.join(router.path, resource_id)
        end
      end
    end
  end
end
