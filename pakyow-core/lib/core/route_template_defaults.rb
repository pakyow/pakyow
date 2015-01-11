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
        delete :remove, "/#{resource_id}"

        group :collection
        namespace :member, resource_id
        
        post_process do
          # the show route is weird; move it to the end of get routes to avoid conflicts
          if show_index = @routes[:get].find_index { |route| route[2] == :show }
            @routes[:get] << @routes[:get].delete_at(show_index)
          end
        end
      end

    end
  end
end
