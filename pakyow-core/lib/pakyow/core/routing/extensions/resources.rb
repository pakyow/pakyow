# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Routing
    module Extension
      # An extension for defining RESTful Resources. For example:
      #
      #   resources :posts, "/posts" do
      #     list do
      #       # list the posts
      #     end
      #   end
      #
      # +Resource+ is available in all controllers by default.
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
      #   resources :posts, "/posts" do
      #     resources :comments, "/comments" do
      #       list do
      #         # available at GET /posts/:post_id/comments
      #       end
      #     end
      #   end
      #
      # = Collection Routes
      #
      # Routes can be defined for the collection. For example:
      #
      #   resources :posts, "/posts" do
      #     collection do
      #       get "/foo" do
      #         # available at GET /posts/foo
      #       end
      #     end
      #   end
      #
      # = Member Routes
      #
      # Routes can be defined as members. For example:
      #
      #   resources :posts, "/posts" do
      #     member do
      #       get "/foo" do
      #         # available at GET /posts/:post_id/foo
      #       end
      #     end
      #   end
      #
      module Resource
        extend Support::Extension
        restrict_extension Controller

        DEFAULT_PARAM = :id

        apply_extension do
          template :resources do |param: DEFAULT_PARAM|
            resource_id = ":#{param}"
            nested_resource_id = ":#{Support.inflector.singularize(controller.__class_name.name)}_#{param}"

            # Nest resources as members of the current resource
            controller.define_singleton_method :resources do |name, matcher, param: DEFAULT_PARAM, &block|
              expand(:resources, name, File.join(nested_resource_id, matcher), param: param, &block)
            end

            action :update_request_path_for_show, only: [:show]

            controller.class_eval do
              define_method :update_request_path_for_show do
                req.env["pakyow.endpoint.path"].gsub!(resource_id, "show")
              end
            end

            get :list, "/"
            get :new,  "/new"
            post :create, "/"
            get :edit, "/#{resource_id}/edit"
            patch :update, "/#{resource_id}"
            put :replace, "/#{resource_id}"
            delete :remove, "/#{resource_id}"
            get :show, "/#{resource_id}"

            group :collection
            namespace :member, nested_resource_id
          end
        end
      end
    end
  end
end
