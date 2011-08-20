module Pakyow
  module Presenter
    class LazyView < View

      def to_html(*args)
        Pakyow.app.presenter.ensure_root_view_built
        super
      end

      def add_content_to_container(*args)
        Pakyow.app.presenter.ensure_root_view_built
        super
      end

      def find(*args)
        Pakyow.app.presenter.ensure_root_view_built
        super
      end

      def repeat_for(*args, &block)
        Pakyow.app.presenter.ensure_root_view_built
        super
      end

      def reset_container(*args)
        Pakyow.app.presenter.ensure_root_view_built
        super
      end

      def title=(*args)
        Pakyow.app.presenter.ensure_root_view_built
        super
      end

      def bind(*args)
        Pakyow.app.presenter.ensure_root_view_built
        super
      end

    end
  end
end
