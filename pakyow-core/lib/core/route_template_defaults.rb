module Pakyow
  class RouteTemplateDefaults
    def self.defaults
      lambda {
        template(:restful) {
          unnested_path = path.dup
          nested_path { |group, path|
            File.join(path, ":#{group}_id")
          }

          default fn(:default) if fn(:default)

          get '/new', :new, fn(:new) if fn(:new)
          
          # special case for show (view path is overridden)
          if show_fns = fn(:show)
            get '/:id', :show, Array(show_fns).unshift(
              lambda {
                #TODO would like to move this reference out of core
                presenter.view_path = File.join(unnested_path, 'show') if @presenter
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
