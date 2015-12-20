module SetupHelper
  def setup
    Pakyow::App.stage(:test)

    Pakyow::Router.instance.set(:pakyow) {
      expand(:restful, :bar, 'bar') {
        action(:create) {}
        action(:update) {}

        expand(:restful, :baz, 'baz') {
          action(:create) {}
          action(:update) {}
        }
      }
    }

    @context = Pakyow::CallContext.new(mock_request.env)

    Pakyow.app.bindings {
      scope(:foo) {
        restful(:bar)
      }
    }

    Pakyow.app.presenter.load
  end

  def teardown
    Pakyow::Presenter::Binder.instance.reset
  end
end
