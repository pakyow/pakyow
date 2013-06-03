module Pakyow
  module Presenter
    class Presenter
      Pakyow::App.before(:init) {
        @presenter = Presenter.new
      }

      Pakyow::App.before(:route) {
        @presenter = Pakyow.app.presenter.dup
        @presenter.prepare_for_request(@request)
      }

      Pakyow::App.after(:route) {
        if @presenter.presented?
          @found = true
          @response.body = [@presenter.content]
        else
          @found = false unless found?
        end
      }

      Pakyow::App.after(:load) {
        @presenter.load
      }

      Pakyow::App.after(:error) {
        unless config.app.errors_in_browser
          @response.body = [@presenter.content] if @presenter.presented?
        end
      }

      attr_accessor :parser_store, :view_store, :binder

      def initialize
        reset
      end

      def current_view_lookup_store
        view_store(@view_store)
      end

      def view_store(name = nil)
        if name
          @view_stores[name]
        else
          @view_store
        end
      end

      #
      # Methods that are called by core. This is the interface that core expects a Presenter to have
      #

      def load
        load_views

        @binder = Binder.instance.reset
        Pakyow::App.bindings.each_pair {|set_name, block|
          @binder.set(set_name, &block)
        }
      end

      def prepare_for_request(request)
        reset

        @request = request

        if @request && @request.route_path && !@request.route_path.is_a?(Regexp) && @request.route_path.index(':')
          @view_path = StringUtils.remove_route_vars(@request.route_path)
        else
          @view_path = @request && @request.working_path
        end
        @root_path = self.current_view_lookup_store.root_path(@view_path)
      end
      
      def presented?
        self.ensure_root_view_built
        @presented
      end
      
      def content
        return unless view
        view.to_html
      end

      #TODO rename to to use root_view, compiled_view naming convention
      def view
        ensure_root_view_built
        @root_view
      end

      def view=(v)
        @root_view = View.new(v, @view_store)
        @root_view_is_built = true
        @presented = true

        # reset paths
        @view_path = nil
        @root_path = nil
      end

      def root
        @is_compiled = false
        @root ||= View.root_at_path(@root_path, @view_store) 
      end

      def root=(v)
        @is_compiled = false
        @root = v
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

      #
      # Used by LazyView
      #

      def ensure_root_view_built
        build_root_view unless @root_view_is_built
      end

      def reset
        @view_store = :default
        @presented = false
        @root_view_is_built = false
      end

      #
      protected
      #

      def build_root_view
        @root_view_is_built = true

        return unless v_p = @view_path

        return unless view_info = self.current_view_lookup_store.view_info(v_p)
        @root_path ||= view_info[:root_view]

        if Config::Base.presenter.view_caching
          r_v = @populated_root_view_cache.get([v_p, @root_path]) {
            populate_view(LazyView.new(@root_path, @view_store, true), view_info[:views])
          }
          @root_view = r_v.dup
          @presented = true
        else
          @root_view = populate_view(LazyView.new(@root_path, @view_store, true), view_info[:views])
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
        @view_stores = {}
        Config::Presenter.view_stores.each_pair {|name, path|
          @view_stores[name] = ViewLookupStore.new(path)
        }

        if Config::Base.presenter.view_caching then
          @populated_root_view_cache = build_root_view_cache(self.current_view_lookup_store.view_info)
        end
      end

      def build_root_view_cache(view_info)
        cache = Pakyow::Cache.new
        view_info.each{|dir,info|
          r_v = LazyView.new(info[:root_view], @view_store, true)
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

          v = populate_view(View.new(path, @view_store), views)
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
