module Pakyow
  module Presenter
    class Presenter < PresenterBase
      class << self
        attr_accessor :proc
      end

      attr_accessor :current_context, :parser_store

      def initialize
        reset_state
      end

      def scope(name, set = :default, &block)
        @bindings[set] ||= {}

        bs = Bindings.for(block)
        @bindings[set][name] = bs
        bs
      end

      def bindings(scope)
        #TODO think about merging on launch instead
        @bindings.inject(Bindings.new) { |bs, b| bs.merge(b[1][scope]) }
      end

      def reset_bindings(set = :default)
        @bindings[set] = {}
      end

      def current_view_store
        @view_lookup_store
      end

      #
      # Methods that are called by core. This is the interface that core expects a Presenter to have
      #

      def load
        load_views

        @bindings ||= {}
        self.reset_bindings
        self.instance_eval(&Presenter.proc) if Presenter.proc
      end

      def prepare_for_request(request)
        reset_state()
        @request = request

        if @request && @request.route_path && !@request.route_path.is_a?(Regexp) && @request.route_path.index(':')
          @view_path = StringUtils.remove_route_vars(@request.route_path)
        else
          @view_path = @request && @request.working_path
        end
        @root_path = @view_lookup_store.root_path(@view_path)
      end
      
      def reset
        @request = nil
        reset_state
      end
      
      def presented?
        #TODO the right thing to do?
        self.ensure_root_view_built
        
        @presented
      end
      
      def content
        return unless view
        request_container = @request.params[:_container] if @request
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

      def view=(v)
        # TODO: Why is it important to dup here?
        @root_view = View.new(v)
        @root_view_is_built = true
        @presented = true
      end

      def root
        @is_compiled = false
        @root ||= View.root_at_path(@root_path) 
      end

      def root=(v)
        @is_compiled = false
        @root = v
      end

      def limit_to_container(id)
        @container_name = id
      end

      def view_path
        @view_path
      end

      def view_path=(path)
        @is_compiled = false
        @view_path = path
      end

      def root_path
        @root_path
      end

      def root_path=(abstract_path)
        @is_compiled = false
        @root = nil
        @root_path = abstract_path
      end

      # Call as part of View DSL for DOM manipulation
      #

      def with_container(container, &block)
        v = self.view.find("##{container}").first
        ViewContext.new(v).instance_exec(v, &block)
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

        return unless v_p = @view_path

        return unless view_info = @view_lookup_store.view_info(v_p)
        @root_path ||= view_info[:root_view]

        if Configuration::Base.presenter.view_caching
          r_v = @populated_root_view_cache.get([v_p, @root_path]) {
            populate_view(LazyView.new(@root_path, true), view_info[:views])
          }
            @root_view = r_v.dup
            @presented = true
        else
          @root_view = populate_view(LazyView.new(@root_path, true), view_info[:views])
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
        cache = Pakyow::Cache.new
        view_info.each{|dir,info|
          r_v = LazyView.new(info[:root_view], true)
          populate_view(r_v, info[:views])
          key = [dir, info[:root_view]]
          cache.put(key, r_v)
        }
        cache
      end

      # populates the top_view using view_store data by recursively building
      # and substituting in child views named in the structure
      def populate_view(top_view, views)
        top_view.containers.each {|e|
          next unless path = views[e[:name]]

          v = populate_view(View.new(path), views)
          self.reset_container(e[:doc])
          self.add_content_to_container(v, e[:doc])
        }
        top_view
      end

      def parser(format, &block)
        @parser_store ||= {}
        @parser_store[format.to_sym] = block
      end

      def add_content_to_container(content, container)
        content = content.doc unless content.class == String || content.class == Nokogiri::HTML::DocumentFragment || content.class == Nokogiri::XML::Element
        container.add_child(content)
      end

      def reset_container(container)
        container.inner_html = ''
      end

    end
  end
end
