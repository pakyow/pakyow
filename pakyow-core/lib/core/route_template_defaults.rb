Pakyow::Router.instance.set(:default) {
  template(:restful) {
    get '/', fn(:index)

    # special case for show (view path is overridden)
    if show_fns = fn(:show)
      show_fns = [show_fns] unless show_fns.is_a?(Array)
      get '/:id', show_fns.unshift(
        lambda {
          presenter.view_path = File.join(self.path, 'show') if Configuration::Base.app.presenter
        }
      )
    end

    get '/new', fn(:new)
    post '/', fn(:create)

    get '/:id/edit', fn(:edit)
    put '/:id', fn(:update)

    delete '/:id', fn(:delete)
  }
}
