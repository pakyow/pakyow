# frozen_string_literal: true

module Pakyow
  class Controller
    known_events :render

    after :route do
      if app.includes_framework?(:presenter) && auto_render?
        render
      else
        next
      end
    end

    def auto_render?
      req.method == :get && (found? || !app.config.presenter.require_route)
    end

    def render(path = request.route_path || request.path, as: nil)
      path = String.normalize_path(path)

      if info = find_info_for(path)
        unless presenter = find_presenter_for(as || path)
          presenter = Presenter::ViewPresenter
        end

        @current_presenter = presenter.new(
          binders: app.state_for(:binder),
          path_builder: app.path_builder,
          **info
        )

        if current_router
          current_router.presentables.each do |name, opts|
            value = value_for_presentable(opts)
            @current_presenter.define_singleton_method name do
              value
            end
          end
        end

        call_hooks :before, :render

        if app.config.routing.enabled
          halt StringIO.new(@current_presenter)
        else
          halt StringIO.new(@current_presenter.view.to_html(clean: false))
        end
      elsif found? # matched a route, but couldn't find a view to present
        raise Presenter::MissingView.new("No view at path `#{path}'")
      end
    end

    protected

    def find_info_for(path)
      collapse_path(path) do |collapsed_path|
        if info = info_for_path(collapsed_path)
          return info
        end
      end
    end

    def find_presenter_for(path)
      return unless app.config.routing.enabled

      collapse_path(path) do |collapsed_path|
        if presenter = presenter_for_path(collapsed_path)
          return presenter
        end
      end
    end

    def info_for_path(path)
      app.state_for(:template_store).lazy.map { |store|
        store.info(path)
      }.find(&:itself)
    end

    def presenter_for_path(path)
      app.state_for(:view).find { |presenter|
        presenter.path == path
      }
    end

    def collapse_path(path)
      yield path; return if path == "/"

      yield path.split("/").keep_if { |part|
        part[0] != ":"
      }.join("/")

      nil
    end

    def value_for_presentable(opts)
      if opts.key?(:value)
        value = opts[:value]
      elsif opts.key?(:method_name)
        begin
          value = current_router.__send__(opts[:method_name])
        rescue NoMethodError
          fail "could not find presentable state for `#{opts[:method_name]}' on #{current_router}"
        end
      else
        value = current_router.instance_exec(&opts[:block]) if opts[:block]
        value = opts[:default_value] unless value
      end

      value
    end
  end
end
