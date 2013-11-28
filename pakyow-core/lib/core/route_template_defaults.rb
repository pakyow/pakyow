module Pakyow
  module Routes
    module Restful
      include Pakyow::Routes

      template :restful do
        resource_id = ":#{@group}_id"

        nested_path { |path| File.join(path, resource_id) }
        view_path = direct_path.gsub(/:[^\/]+/, '').split('/').reject { |p| p.empty? }.join('/')

        fn :reset_view_path do
          presenter.path = File.join(view_path, 'show') if @presenter
        end

        get :list, '/'
        get :new,  '/new'
        get :show, "/#{resource_id}", before: [:reset_view_path]

        post :create, '/'

        get :edit, "/#{resource_id}/edit"
        patch :update, "/#{resource_id}"
        put :replace, "/#{resource_id}"
        delete :delete, "/#{resource_id}"

        group :collection
        namespace :member, resource_id
      end

    end
  end
end
