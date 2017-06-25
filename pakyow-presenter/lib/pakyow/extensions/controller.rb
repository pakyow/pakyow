module Pakyow
  class Controller
    def render(path = request.route_path || request.path, as: nil)
      if info = find_info_for(path)
        unless presenter = find_presenter_for(as || path)
          presenter = Presenter::ViewPresenter
        end

        presenter_instance = presenter.new(
          # presenters: app.state_for(:presenter),
          binders: app.state_for(:binder),
          **info
        )

        current_router.presentables.each do |presentable|
          begin
            value = current_router.__send__(presentable)
          rescue NoMethodError
            fail "could not find presentable state for `#{presentable}' on #{current_router}"
          end

          presenter_instance.define_singleton_method presentable do
            value
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

      nil
    end

    def find_presenter_for(path)
      collapse_path(path) do |collapsed_path|
        if presenter = presenter_for_path(collapsed_path)
          return presenter
        end
      end

      nil
    end

    def info_for_path(path)
      app.state_for(:template_store).lazy.map { |store|
        store.at_path(path)
      }.find(&:itself)
    end

    def presenter_for_path(path)
      app.state_for(:view).lazy.find { |presenter|
        presenter.path == path
      }
    end

    def collapse_path(path)
      yield path; return if path == "/"

      parts = path.split("/").keep_if { |part|
        part[0] != ":"
      }

      parts.count.downto(1) do |count|
        yield parts.take(count).join("/")
      end
    end
  end
end
