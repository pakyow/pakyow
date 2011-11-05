module Pakyow
  module Presenter
    class Presenter < PresenterBase
      attr_accessor :current_context

      def initialize
        reset_state()
      end

      #
      # Methods that are called by core. This is the interface that core expects a Presenter to have
      #

      def load
        load_views
      end

      def prepare_for_request(request)
        reset_state()
        @request = request
      end
      
      def presented?
        @presented
      end
      
      def content
        return unless view
        request_container = @request.params[:_container]
        return view.to_html(request_container) if request_container
        view.to_html(@container_name)
      end

      #
      # Methods that a controller can call to get and modify the root view.
      # Some are meant to be called directly and some make up a dsl for dom modification
      #

      # Call these directly
      #

      def view_for_path(abstract_path, is_root_view=false, klass=View)
        real_path = @view_lookup_store.real_path(abstract_path)
        klass.new(real_path, is_root_view)
      end

      def view_for_class(view_class, path_override=nil)
        return view_for_path(path_override, view_class.default_is_root_view, view_class) if path_override
        view_for_path(view_class.default_view_path, view_class.default_is_root_view, view_class)
      end

      def view
        ensure_root_view_built
        @root_view
      end

      def set_view(view)
        @root_view = View.new(view)
        @root_view_is_built = true
        @presented = true
        @view_path = nil
        @root_path = nil
      end

      def limit_to_container(id)
        @container_name = id
      end

      def use_view_path(path)
        @view_path = path
        @root_view_is_built = false
      end

      def view_path
        @view_path
      end

      def use_root_view_file(abstract_view_file)
        real_path = @view_lookup_store.real_path(abstract_view_file)
        @root_path = real_path
        @root_view_is_built = false
      end

      def use_root_view_at_view_path(abstract_view_dir)
        @root_path = @view_lookup_store.view_info(abstract_view_dir)[:root_view]
        @root_view_is_built = false
      end
      
      # This is for creating views from within a controller using the route based lookup mechanism
      def view_for_view_path(v_p, name, deep = false)
        v = nil
        view_info = @view_lookup_store.view_info(v_p)
        vpath = view_info[:views][name] if view_info
        v = View.new(vpath) if vpath
        if v && deep
          populate_view(v, view_info[:views])
        end
        v
      end

      # This is also for creating views from within a controller using the route based lookup mechanism.
      # This method takes either a dir or file path and builds either a root_view or view, respectively.
      def view_for_full_view_path(f_v_p, deep = false)
        v = nil
        real_path_info = @view_lookup_store.real_path_info(f_v_p)
        if real_path_info
          if real_path_info[:file_or_dir] == :file
            v = View.new(real_path_info[:real_path])
          elsif real_path_info[:file_or_dir] == :dir
            root_view = @view_lookup_store.view_info(f_v_p)[:root_view]
            v = View.new(root_view)
            if v && deep
              populate_view(v, @view_lookup_store.view_info(f_v_p)[:views])
            end
          end
        end
        v
      end

      def populate_view_for_view_path(view, v_p)
        return view unless view_info = @view_lookup_store.view_info(v_p)
        views = view_info[:views]
        populate_view(view, views)
        view
      end

      # Call as part of View DSL for DOM manipulation
      #

      def with_container(container, &block)
        ViewContext.new(self.view.find("##{container}").first).instance_eval(&block)
      end

      #
      # Used by LazyView
      #

      def ensure_root_view_built
        build_root_view unless @root_view_is_built
      end

      #
      protected
      #

      def reset_state
        @presented = false
        @root_path = nil
        @root_view_is_built = false
        @root_view = nil
        @view_path = nil
        @container_name = nil
      end

      def build_root_view
        @root_view_is_built = true

        if @view_path
          v_p = @view_path
        elsif @request && @request.restful
          v_p = restful_view_path(@request.restful)
        elsif @request && @request.route_spec && @request.route_spec.index(':')
          v_p = StringUtils.remove_route_vars(@request.route_spec)
        else
          v_p = @request && @request.working_path
        end
        return unless v_p

        if Configuration::Base.presenter.view_caching
          r_v = @populated_root_view_cache[v_p]
          if r_v then
            @root_view = r_v.dup
            @presented = true
          end
        else
          return unless view_info = @view_lookup_store.view_info(v_p)
          @root_path ||= view_info[:root_view]
          @root_view = LazyView.new(@root_path, true)
          views = view_info[:views]
          populate_view(self.view, views)
          @presented = true
        end
      end
      
      def restful_view_path(restful_info)
        if restful_info[:restful_action] == :show
          "#{StringUtils.remove_route_vars(@request.route_spec)}/show"
        else
          StringUtils.remove_route_vars(@request.route_spec)
        end
      end

      def load_views
        @view_lookup_store = ViewLookupStore.new("#{Configuration::Presenter.view_dir}")
        if Configuration::Base.presenter.view_caching then
          @populated_root_view_cache = build_root_view_cache(@view_lookup_store.view_info)
        end
      end

      def build_root_view_cache(view_info)
        r_v_c = {}
        view_info.each{|dir,info|
          r_v = LazyView.new(info[:root_view], true)
          populate_view(r_v, info[:views])
          r_v_c[dir] = r_v
        }
        r_v_c
      end

      # populates the top_view using view_store data by recursively building
      # and substituting in child views named in the structure
      def populate_view(top_view, views)
        containers = top_view.elements_with_ids
        containers.each {|e|
          name = e.attr("id")
          path = views[name]
          if path
            v = populate_view(View.new(path), views)
            top_view.reset_container(name) # TODO revisit how this is implemented; assumes all LazyViews are root views
            top_view.add_content_to_container(v, name)
          end
        }
        top_view
      end

    end
  end
end
