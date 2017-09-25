module Pakyow
  class Controller
    after :route do
      next if app.config.presenter.require_route && !found?
      render
    end

    def render(path = request.route_path || request.path, as: nil)
      path = String.normalize_path(path)

      if info = find_info_for(path)
        unless presenter = find_presenter_for(as || path)
          presenter = Presenter::ViewPresenter
        end

        presenter_instance = presenter.new(
          binders: app.state_for(:binder),
          controller: self,
          **info
        )

        if current_router
          current_router.presentables.each do |name, opts|
            if opts.key?(:value)
              value = opts[:value]
            elsif opts.key?(:method_name)
              begin
                value = current_router.__send__(opts[:method_name])
              rescue NoMethodError
                fail "could not find presentable state for `#{opts[:method_name]}' on #{current_router}"
              end
            else
              value = opts[:default_value]
              value = opts[:block].call if value.nil? && opts[:block]
            end

            presenter_instance.define_singleton_method name do
              value
            end
          end
        end

        halt StringIO.new(presenter_instance)
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
  end
end
