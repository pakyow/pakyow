module Pakyow
  class RouteTemplateDefaults
    def self.defaults
      lambda {
        template(:restful) {
          nested_path { |group, path|
            File.join(path, ":#{group}_id")
          }

          default fn(:default) if fn(:default)

          get '/new', :new, fn(:new) if fn(:new)
          
          # special case for show (view path is overridden)
          if show_fns = fn(:show)
            show_fns = [show_fns] unless show_fns.is_a?(Array)
            path = self.path
            get '/:id', :show, show_fns.unshift(
              lambda {
                presenter.view_path = File.join(path, 'show') if Config::Base.app.presenter
              }
            )
          end

          
          post '/', :create, fn(:create) if fn(:create)

          get '/:id/edit', :edit, fn(:edit) if fn(:edit)
          put '/:id', :update, fn(:update) if fn(:update)

          delete '/:id', :delete, fn(:delete) if fn(:delete)
        }
      }
    end
  end
end
