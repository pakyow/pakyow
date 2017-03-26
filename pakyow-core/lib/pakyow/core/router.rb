require "pakyow/support/aargv"
require "pakyow/support/array"

require "pakyow/core/routing/hook_merger"

module Pakyow
  # Executes code for particular requests. For example:
  #
  #   Pakyow::App.router do
  #     get "/" do
  #       # called for GET / requests
  #     end
  #   end
  #
  # A +Class+ is created dynamically for each defined router. When matched, a route
  # is called in context of its router. This means that any method defined in a
  # router is available to be called from within a route. For example:
  #
  #   Pakyow::App.router do
  #     def foo
  #     end
  #
  #     get :foo, "/foo" do
  #       foo
  #     end
  #   end
  #
  # Including modules works as expected:
  #
  #   module AuthHelpers
  #     def current_user
  #     end
  #   end
  #
  #   Pakyow::App.router do
  #     include AuthHelpers
  #
  #     get :foo, "/foo" do
  #       current_user
  #     end
  #   end
  #
  # See {App.router} for more details on defining routers.
  #
  # = Supported HTTP methods
  #
  # - +GET+
  # - +POST+
  # - +PUT+
  # - +PATCH+
  # - +DELETE+
  #
  # See {get}, {post}, {put}, {patch}, and {delete}.
  #
  # +HEAD+ requests are handled automatically via {Rack::Head}.
  #
  # = Building paths for named routes
  #
  # Path building is supported via {Controller#path} and {Controller#path_to}.
  #
  # = Reusing logic with hooks
  #
  # Methods can be defined and used as hooks for a route. For example:
  #
  #   Pakyow::App.router do
  #     def foo
  #     end
  #
  #     get :foo, "/foo", before: [:foo] do
  #     end
  #   end
  #
  # Before, after, and around hooks are supported in this way.
  #
  # = Extending routers
  #
  # Extensions can be defined and used to add shared routes to one or more
  # routers. See {Routing::Extension}.
  #
  # = Other routing features
  #
  # More advanced route features are available, including groups, namespaces,
  # and templates. See {group}, {namespace}, and {template}.
  #
  # = Router subclasses
  #
  # It's possible to work with routers outside of Pakyow's DSL. For example:
  #
  #   class FooRouter < Pakyow::Router("/foo", after: [:bar])
  #     def bar
  #     end
  #
  #     default do
  #       # available at GET /foo
  #     end
  #   end
  #
  #   Pakyow::App.router << FooRouter
  #
  # = Custom matchers
  #
  # Routers and routes can be defined with a matcher, which could be a +Regexp+ or
  # any custom object that implements +match?+. For example:
  #
  #   class CustomMatcher
  #     def match?(path)
  #       path == "/custom"
  #     end
  #   end
  #
  #   Pakyow::App.router CustomMatcher.new do
  #   end
  #
  # Custom matchers can also make data available in +params+ by implementing
  # +match+ and returning an object that implements +named_captures+.
  # For example:
  #
  #   class CustomMatcher
  #     def match?(path)
  #       path == "/custom"
  #     end
  #
  #     def match(path)
  #       return self if match?(path)
  #     end
  #
  #     def named_captures
  #       { foo: "bar" }
  #     end
  #   end
  #
  #   Pakyow::App.router CustomMatcher.new do
  #   end
  #
  # When defined on a Router, custom matchers should also implement +sub+,
  # which returns the unmatched part of the path. This value will be used
  # when matching nested routers and routes.
  #
  # @api public
  class Router
    include Helpers
    using Support::DeepDup
    extend Pakyow::Routing::HookMerger

    router = self
    (class << Pakyow; self; end).send(:define_method, :Router) do |path, **hooks|
      router.Router(path, **hooks)
    end

    METHOD_GET    = :get
    METHOD_POST   = :post
    METHOD_PUT    = :put
    METHOD_PATCH  = :patch
    METHOD_DELETE = :delete

    SUPPORTED_HTTP_METHODS = [
      METHOD_GET,
      METHOD_POST,
      METHOD_PUT,
      METHOD_PATCH,
      METHOD_DELETE
    ].freeze

    DEFAULT_EXTENSIONS = [
      "Pakyow::Routing::Extension::Resource".freeze
    ].freeze

    extend Forwardable

    # @!method logger
    #   Delegates to {context}.
    #
    #   @see Controller#logger
    #
    # @!method handle
    #   Delegates to {context}.
    #
    #   @see Controller#handle
    #
    # @!method redirect
    #   Delegates to {context}.
    #
    #   @see Controller#redirect
    #
    # @!method reroute
    #   Delegates to {context}.
    #
    #   @see Controller#reroute
    #
    # @!method send
    #   Delegates to {context}.
    #
    #   @see Controller#send
    #
    # @!method reject
    #   Delegates to {context}.
    #
    #   @see Controller#reject
    #
    # @!method trigger
    #   Delegates to {context}.
    #
    #   @see Controller#trigger
    #
    # @!method path
    #   Delegates to {context}.
    #
    #   @see Controller#path
    #
    # @!method path_to
    #   Delegates to {context}.
    #
    #   @see Controller#path_to
    #
    # @!method halt
    #   Delegates to {context}.
    #
    #   @see Controller#halt
    #
    # @!method config
    #   Delegates to {context}.
    #
    #   @see Controller#config
    #
    # @!method params
    #   Delegates to {context}.
    #
    #   @see Controller#params
    #
    # @!method session
    #   Delegates to {context}.
    #
    #   @see Controller#session
    #
    # @!method :cookies
    #   Delegates to {context}.
    #
    #   @see Controller#:cookies
    #
    # @!method request
    #   Delegates to {context}.
    #
    #   @see Controller#request
    #
    # @!method response
    #   Delegates to {context}.
    #
    #   @see Controller#response
    #
    # @!method req
    #   Delegates to {context}.
    #
    #   @see Controller#req
    #
    # @!method res
    #   Delegates to {context}.
    #
    #   @see Controller#res
    #
    # @!method respond_to
    #   Delegates to {context}.
    #
    #   @see Controller#respond_to
    def_delegators :@controller, :logger, :handle, :redirect, :reroute, :send, :reject, :trigger, :path, :path_to,
                   :halt, :config, :params, :session, :cookies, :request, :response, :req, :res, :respond_to

    # The context of the current request lifecycle.
    # Expected to be an instance of {Controller}.
    attr_accessor :controller

    # @api private
    def initialize(controller)
      @controller = controller
    end

    # Copies state from self to +router+.
    #
    # @api private
    def handoff_to(router)
      instance_variables.each do |ivar|
        next if router.instance_variable_defined?(ivar)
        router.instance_variable_set(ivar, instance_variable_get(ivar))
      end
    end

    # @api private
    def trigger_for_code(code, handlers: {})
      return unless handler = self.class.handler_for_code(code, handlers: handlers)
      instance_exec(&handler); true
    end

    class << self
      # Conveniently define defaults when subclassing +Pakyow::Router+.
      #
      # @example
      #   class MyRouter < Pakyow::Router("/foo", before: [:foo])
      #     # more routes here
      #   end
      #
      # @api public
      def Router(matcher, before: [], after: [], around: [])
        Class.new(self) do
          @matcher = finalize_matcher_and_set_path(matcher)
          @hooks = { before: before, after: after, around: around }
        end
      end

      # Create a default route. Shorthand for +get "/"+.
      #
      # @see get
      #
      # @api public
      def default(**hooks, &block)
        get :default, "/", **hooks, &block
      end

      # @!method get
      #   Create a route that matches +GET+ requests at +path+. For example:
      #
      #     Pakyow::App.router do
      #       get "/foo" do
      #         # do something
      #       end
      #     end
      #
      #   Routes can be named, making them available for path building via
      #   {Controller#path}. For example:
      #
      #     Pakyow::App.router do
      #       get :foo, "/foo" do
      #         # do something
      #       end
      #     end
      #
      #   Routes can be defined with +before+, +after+, or +around+ hooks.
      #   For example:
      #
      #     Pakyow::App.router do
      #       def bar
      #       end
      #
      #       get :foo, "/foo", before: [:bar] do
      #         # do something
      #       end
      #     end
      #
      # @!method post
      #   Create a route that matches +POST+ requests at +path+, with +hooks+.
      #
      #   @see get
      #
      # @!method put
      #   Create a route that matches +PUT+ requests at +path+, with +hooks+.
      #
      #   @see get
      #
      # @!method patch
      #   Create a route that matches +PATCH+ requests at +path+, with +hooks+.
      #
      #   @see get
      #
      # @!method delete
      #   Create a route that matches +DELETE+ requests at +path+, with +hooks+.
      #
      #   @see get
      #
      SUPPORTED_HTTP_METHODS.each do |http_method|
        define_method http_method do |name_or_matcher = nil, matcher_or_name = nil, **hooks, &block|
          build_route(http_method, name_or_matcher, matcher_or_name, **hooks, &block)
        end
      end

      # Creates a nested group of routes, with an optional name and
      # hooks. Hooks defined on the group will be inherited by each
      # route present in the group. Groups also inherit hooks
      # defined in their parent scopes.
      #
      # Named groups make the routes available for path building.
      # Paths to routes defined in unnamed groups are referenced
      # by the most direct parent group that is named.
      #
      # @example Defining a group:
      #   Pakyow::App.router do
      #     def foo
      #       logger.info "foo"
      #     end
      #
      #     group :foo, before: [:foo] do
      #       def bar
      #         logger.info "bar"
      #       end
      #
      #       get :bar, "/bar", before: [:bar] do
      #         # "foo" and "bar" have both been logged
      #         send "foo.bar"
      #       end
      #     end
      #
      #     group before: [:foo] do
      #       get :baz, "/baz" do
      #         # "foo" has been logged
      #         send "baz"
      #       end
      #     end
      #   end
      #
      # @example Building a path to a route within a named group:
      #   path :foo_bar
      #   # => "/foo/bar"
      #
      # @example Building a path to a route within an unnamed group:
      #   path :foo_baz
      #   # => nil
      #
      #   path :baz
      #   # => "/baz"
      #
      # @api public
      def group(name = nil, **hooks, &block)
        make_child(name, nil, **hooks, &block)
      end

      # Creates a group of routes and mounts them at a path, with an optional
      # name as well as hooks. A namespace behaves just like a group with
      # regard to path lookup and hook inheritance.
      #
      # @example Defining a namespace:
      #   Pakyow::App.router do
      #     namespace :api, "/api" do
      #       def auth
      #         handle 401 unless authed?
      #       end
      #
      #       group before: [:auth] do
      #         namespace :project, "/projects" do
      #           get :list, "/" do
      #             # route is accessible via 'GET /api/projects'
      #             send projects.to_json
      #           end
      #         end
      #       end
      #     end
      #   end
      #
      def namespace(*args, **hooks, &block)
        name, matcher = parse_name_and_matcher_from_args(*args)
        make_child(name, matcher, **hooks, &block)
      end

      # Creates a route template with a name and block. The block is
      # evaluated within a {Routing::Expansion} instance when / if it
      # is later expanded at some endpoint (creating a namespace).
      #
      # Route templates are used to define a scaffold of default routes
      # that will later be expanded at some path. During expansion, the
      # scaffolded routes are also mapped to routing logic.
      #
      # Because routes can be referenced by name during expansion, route
      # templates provide a way to create a domain-specific-language, or
      # DSL, around a routing concern. This is used within Pakyow itself
      # to define the resource template ({Routing::Extension::Resource}).
      #
      # @example Defining a template:
      #   Pakyow::App.router do
      #     template :talkback do
      #       get :hello, "/hello"
      #       get :goodbye, "/goodbye"
      #     end
      #   end
      #
      # @example Expanding a template:
      #
      #   Pakyow::App.router do
      #     talkback :en, "/en" do
      #       hello do
      #         send "hello"
      #       end
      #
      #       goodbye do
      #         send "goodbye"
      #       end
      #
      #       # we can also extend the expansion
      #       # for our particular use-case
      #       get "/thanks" do
      #         send "thanks"
      #       end
      #     end
      #
      #     talkback :fr, "/fr" do
      #       hello do
      #         send "bonjour"
      #       end
      #
      #       # `goodbye` will not be an endpoint
      #       # since we did not expand it here
      #     end
      #   end
      #
      def template(name, &template_block)
        templates[name] = template_block
      end

      # Expands a defined route template, or raises +NameError+.
      #
      # @see template
      #
      # @api public
      def expand(name, *args, **hooks, &block)
        make_child(*args, **hooks).expand_within(name, &block)
      end

      # Registers an error handler used within this router.
      #
      # @example Handling a status code:
      #   Pakyow::App.router do
      #     handle 500 do
      #       # handle 500 responses
      #     end
      #
      #     default do
      #       trigger 500
      #     end
      #   end
      #
      # @example Handling a status code by name:
      #   Pakyow::App.router do
      #     handle :forbidden do
      #       # handle 403 responses
      #     end
      #
      #     default do
      #       trigger 403 # or, `trigger :forbidden`
      #     end
      #   end
      #
      # @example Handling an exception:
      #   handle Sequel::NoMatchingRow, as: 404 do
      #     # handle missing records
      #   end
      #
      #   Pakyow::App.router do
      #     default do
      #       raise Sequel::NoMatchingRow
      #     end
      #   end
      #
      # @api public
      def handle(name_exception_or_code, as: nil, &block)
        if name_exception_or_code.is_a?(Class) && name_exception_or_code.ancestors.include?(Exception)
          raise ArgumentError, "status code is required" if as.nil?
          exceptions[name_exception_or_code] = [Rack::Utils.status_code(as), block]
        else
          handlers[Rack::Utils.status_code(name_exception_or_code)] = block
        end
      end

      # Defines routes within another router.
      #
      # @example
      #   Pakyow::App.define do
      #     router :api do
      #     end
      #
      #     resource :project, "/projects" do
      #       list do
      #         # GET /projects
      #       end
      #
      #       within :api do
      #         list do
      #           # GET /api/projects
      #         end
      #       end
      #     end
      #   end
      #
      # @api public
      def within(*names, &block)
        raise NameError, "Unknown router `#{names.first}'" unless router = find_router_by_name(names)
        router.make_child(name, matcher, **hooks, &block)
      end

      # Attempts to find and expand a template, avoiding the need to call
      # {expand} explicitly. For example, these calls are identical:
      #
      #   Pakyow::App.router do
      #     resource :post, "/posts" do
      #     end
      #
      #     expand :resource, :post, "/posts" do
      #     end
      #   end
      #
      # @api public
      def method_missing(name, *args, **hooks, &block)
        if templates.include?(name)
          expand(name, *args, **hooks, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        templates.include?(method_name) || super
      end

      # @api private
      attr_reader :name, :path, :matcher, :state

      # @api private
      attr_accessor :parent

      # @api private
      def hooks
        @hooks ||= { before: [], after: [], around: [] }
      end

      # @api private
      def children
        @children ||= []
      end

      # @api private
      def templates
        @templates ||= {}
      end

      # @api private
      def handlers
        @handlers ||= {}
      end

      # @api private
      def exceptions
        @exceptions ||= {}
      end

      # @api private
      def reset
        @hooks, @children, @templates, @handlers, @exceptions = nil
      end

      # @api private
      def inherited(klass)
        matcher = self.matcher
        hooks = self.hooks.deep_dup
        templates = self.templates.deep_dup
        handlers = self.handlers.deep_dup
        exceptions = self.exceptions.deep_dup

        klass.class_eval do
          @matcher = matcher
          @hooks = hooks
          @templates = templates
          @handlers = handlers
          @exceptions = exceptions

          DEFAULT_EXTENSIONS.each do |extension|
            include(Kernel.const_get(extension))
          end
        end
      end

      def path_to_self
        return path unless parent
        File.join(parent.path_to_self.to_s, path.to_s)
      end

      # @api private
      def path_to(*names, **params)
        # look for a matching route before descending into child routers
        combined_name = names.join("_").to_sym
        if found_route = routes.values.flatten.find { |route| route.name == combined_name }
          return found_route.populated_path(path_to_self, **params)
        end

        matched_routers = children.reject { |router_to_match|
          # TODO: make this a method on router to call from here and controller
          router_to_match.name.nil? || router_to_match.name != names.first
        }

        matched_routers.each do |matched_router|
          if path = matched_router.path_to(*names[1..-1], **params)
            return path
          end
        end

        nil
      end

      # @api private
      def make(*args, before: [], after: [], around: [], state: nil, parent: nil, &block)
        name, matcher = parse_name_and_matcher_from_args(*args)
        klass = const_for_router_named(Class.new(self), name)

        klass.class_eval do
          @name = name
          @matcher = finalize_matcher_and_set_path(matcher)
          @state = state
          @parent = parent
          @hooks = compile_hooks(before: before, after: after, around: around)
          class_eval(&block) if block
        end

        klass
      end

      # @api private
      def make_child(*args, **hooks, &block)
        router = make(*args, parent: self, **hooks, &block)
        children << router
        router
      end

      # @api private
      def routes
        @routes ||= SUPPORTED_HTTP_METHODS.each_with_object({}) do |method, routes_hash|
          routes_hash[method] = []
        end
      end

      # @api private
      def match_router_and_route(path, method, match_data = {}, &block)
        return if matcher && !matcher.match?(path)

        if matcher.respond_to?(:match)
          # TODO: need this all to be in a helper and shared with Route
          match_data.merge!(matcher.match(path).named_captures)
        end

        if matcher.is_a?(Regexp)
          path = String.normalize_path(path.sub(matcher, ""))
        end

        children.each do |child_router|
          child_router.match_router_and_route(path, method, match_data, &block)
        end

        routes[method].each do |route|
          next unless route_match_data = route.match(path)
          match_data.merge!(route_match_data) if route_match_data.is_a?(Hash)
          yield self, route, match_data
        end
      end

      # @api private
      def merge(router)
        merge_hooks(router.hooks)
        merge_routes(router.routes)
        merge_templates(router.templates)
      end

      # @api private
      def freeze
        # TODO: let's instead have a deep freeze method that freezes the object and its ivars, recursively
        hooks.each do |_, hooks_arr|
          hooks_arr.each(&:freeze)
          hooks_arr.freeze
        end

        children.each(&:freeze)

        routes.each do |_, routes_arr|
          routes_arr.each(&:freeze)
          routes_arr.freeze
        end

        matcher.freeze
        hooks.freeze
        children.freeze
        routes.freeze
        templates.freeze

        super
      end

      # @api private
      def exception_for_class(klass, exceptions: {})
        self.exceptions.merge(exceptions)[klass]
      end

      # @api private
      def handler_for_code(code, handlers: {})
        self.handlers.merge(handlers)[code]
      end

      # @api private
      def expand_within(name, &block)
        raise NameError, "Unknown template `#{name}'" unless template = templates[name]
        Routing::Expansion.new(name, self, &template)
        class_eval(&block)
      end

      protected

      # Finds a router via +names+, starting with a top-level router.
      #
      # @api private
      def find_router_by_name(names, routers = nil)
        return parent.find_router_by_name(names) if parent

        first_name = names.shift
        (routers || [self].concat(state.instances)).each do |router|
          next unless router.name == first_name

          if names.empty?
            return router
          else
            return router.find_router_by_name(names, router.children)
          end
        end
      end

      def parse_name_and_matcher_from_args(name_or_matcher = nil, matcher_or_name = nil)
        Aargv.normalize([name_or_matcher, matcher_or_name].compact, name: Symbol, matcher: Object).values_at(:name, :matcher)
      end

      def finalize_matcher_and_set_path(matcher)
        if matcher.is_a?(String)
          @path = matcher

          converted_matcher = String.normalize_path(matcher.split("/").map { |segment|
            if segment.include?(":")
              "(?<#{segment[1..-1]}>(\\w|[-.~:@!$\\'\\(\\)\\*\\+,;])*)"
            else
              segment
            end
          }.join("/"))

          Regexp.new("^#{String.normalize_path(converted_matcher)}")
        else
          matcher
        end
      end

      def build_route(method, *args, **hooks, &block)
        name, matcher = parse_name_and_matcher_from_args(*args)

        route = Routing::Route.new(
          matcher,
          method: method,
          name: name,
          hooks: compile_hooks(hooks || {}),
          &block
        )

        routes[method] << route; route
      end

      def compile_hooks(hooks_to_compile)
        hooks.each_with_object({}) do |(type, hooks), combined|
          combined[type] = hooks.dup.concat(
            Array.ensure(hooks_to_compile[type] || [])
          ).uniq
        end
      end

      def merge_routes(routes_to_merge)
        routes.each_pair do |type, routes_of_type|
          routes_of_type.concat(routes_to_merge[type].map { |route_to_merge|
            route_to_merge.dup
          })
        end
      end

      def merge_templates(templates_to_merge)
        templates.merge!(templates_to_merge)
      end

      def const_for_router_named(router_class, name)
        return router_class if name.nil?

        # convert snake case to camel case
        class_name = "#{name.to_s.split('_').map(&:capitalize).join}Router"

        if Object.const_defined?(class_name)
          router_class
        else
          Object.const_set(class_name, router_class)
        end
      end
    end
  end
end
