require "pakyow/core/routing/extension"

module Pakyow
  module Routing
    module Extensions
      module Restful
        include Extension

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
