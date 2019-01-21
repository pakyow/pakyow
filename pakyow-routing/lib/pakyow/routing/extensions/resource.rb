# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Routing
    module Extension
      # An extension for defining RESTful Resources. For example:
      #
      #   resource :posts, "/posts" do
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
      # - +delete+ -- +DELETE /:resource_id+
      # - +show+ -- +GET /:resource_id+
      #
      # = Nested Resources
      #
      # Resources can be nested. For example:
      #
      #   resource :posts, "/posts" do
      #     resource :comments, "/comments" do
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
      #   resource :posts, "/posts" do
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
      #   resource :posts, "/posts" do
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
          template :resource do |param: DEFAULT_PARAM|
            resource_id = ":#{param}"
            nested_param = "#{Support.inflector.singularize(controller.__object_name.name)}_#{param}".to_sym
            nested_resource_id = ":#{nested_param}"

            action :update_request_path_for_show, only: [:show] do
              req.env["pakyow.endpoint.path"].gsub!(resource_id, "show")
            end

            controller.class_eval do
              allow_params param

              define_singleton_method :param do
                param
              end

              define_singleton_method :nested_param do
                nested_param
              end

              define_method :update_request_path_for_show do
                req.env["pakyow.endpoint.path"].gsub!(resource_id, "show")
              end

              NestedResource.define(self, nested_resource_id, nested_param)
            end

            get :list, "/"
            get :new,  "/new"
            post :create, "/"
            get :edit, "/#{resource_id}/edit"
            patch :update, "/#{resource_id}"
            put :replace, "/#{resource_id}"
            delete :delete, "/#{resource_id}"
            get :show, "/#{resource_id}"

            group :collection
            namespace :member, nested_resource_id
          end
        end

        module NestedResource
          # Nest resources as members of the current resource.
          #
          def self.define(controller, nested_resource_id, nested_param)
            controller.define_singleton_method :namespace do |*args, &block|
              namespace = super(*args, &block)
              namespace.allow_params nested_param
              namespace.action :update_request_path_for_parent do
                req.env["pakyow.endpoint.path"].gsub!(nested_resource_id, "show")
              end
            end

            controller.define_singleton_method :resource do |name, matcher, param: DEFAULT_PARAM, &block|
              expand(:resource, name, File.join(nested_resource_id, matcher), param: param) do
                allow_params nested_param
                action :update_request_path_for_parent do
                  req.env["pakyow.endpoint.path"].gsub!(nested_resource_id, "show")
                end
                instance_exec(&block)
              end
            end
          end
        end
      end
    end
  end
end
