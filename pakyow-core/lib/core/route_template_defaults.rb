module Pakyow
  class RouteTemplateDefaults
    def self.register
      Pakyow::Router.instance.set(:default) {
        template(:restful) {
          get '/', :index, fn(:index)

          # special case for show (view path is overridden)
          if show_fns = fn(:show)
            show_fns = [show_fns] unless show_fns.is_a?(Array)
            get '/:id', :show, show_fns.unshift(
              lambda {
                presenter.view_path = File.join(self.path, 'show') if Configuration::Base.app.presenter
              }
            )
          end

          get '/new', :new, fn(:new)
          post '/', :create, fn(:create)

          get '/:id/edit', :edit, fn(:edit)
          put '/:id', :update, fn(:update)

          delete '/:id', :delete, fn(:delete)
        }
      }
    end
  end
end
