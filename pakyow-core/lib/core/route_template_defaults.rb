module Pakyow
  class RouteTemplateDefaults
    def self.defaults
      lambda {
        template(:restful) {
          nested_path { |group, path|
            File.join(path, ":#{group}_id")
          }

          get '/', :index, fn(:index) if fn(:index)

          # special case for show (view path is overridden)
          if show_fns = fn(:show)
            show_fns = [show_fns] unless show_fns.is_a?(Array)
            get '/:id', :show, show_fns.unshift(
              lambda {
                presenter.view_path = File.join(self.path, 'show') if Configuration::Base.app.presenter
              }
            )
          end

          get '/new', :new, fn(:new) if fn(:new)
          post '/', :create, fn(:create) if fn(:create)

          get '/:id/edit', :edit, fn(:edit) if fn(:edit)
          put '/:id', :update, fn(:update) if fn(:update)

          delete '/:id', :delete, fn(:delete) if fn(:delete)
        }
      }
    end
  end
end
