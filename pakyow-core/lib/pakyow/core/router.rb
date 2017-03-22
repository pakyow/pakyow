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
  # A dynamic +Class+ is created for each defined router. When matched, a route
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
  # Including modules work as expected:
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
  # @api public
  class Router
    include Helpers
    using Support::DeepDup
    extend Pakyow::Routing::HookMerger

    router = self
    (class << Pakyow; self; end).send(:define_method, :Router) do |path, **hooks|
      router.Router(path, **hooks)
    end

    METHOD_GET    = "GET".freeze
    METHOD_POST   = "POST".freeze
    METHOD_PUT    = "PUT".freeze
    METHOD_PATCH  = "PATCH".freeze
    METHOD_DELETE = "DELETE".freeze

    SUPPORTED_METHODS = [
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
    def_delegators :@context, :logger, :handle, :redirect, :reroute, :send, :reject, :trigger, :path, :path_to,
                              :halt, :config, :params, :session, :cookies, :request, :response, :req, :res,
                              :respond_to

    # The context of the current request lifecycle.
    # Expected to be an instance of {Controller}.
    #
    attr_accessor :context

    # @api private
    def initialize(context)
      if router = context.previous_router
        router.handoff_to(self)
      end

      @context = context
    end

    # Copies state from self to +router+.
    #
    # @api private
    def handoff_to(router)
      self.instance_variables.each do |ivar|
        next if router.instance_variable_defined?(ivar)
        router.instance_variable_set(ivar, instance_variable_get(ivar))
      end
      
      router
    end

    # @api private
    def trigger_for_code(code, context: nil, handlers: {})
      return unless handler = self.class.handler_for_code(code, handlers: handlers)

      if context
        context.instance_exec(&handler)
      else
        handler.call
      end

      true
    end

    # @api private
    def trigger_for_exception(klass, context: nil, handlers: {}, exceptions: {})
      return unless exception = self.class.exception_for_class(klass, exceptions: exceptions)

      code = exception[0]
      if handler = exception[1]
        handlers[code] = handler
      end

      context.response.status = code
      trigger_for_code(code, context: context, handlers: handlers)
    end

    class << self
      # Conveniently define defaults when subclassing +Pakyow::Router+.
      # For example:
      #
      #   class MyRouter < Pakyow::Router("/foo", before: [:foo])
      #     # more routes here
      #   end
      #
      # @api public
      def Router(path, before: [], after: [], around: [])
        Class.new(self) do
          @path = path

          @hooks = {
            before: before, after: after, around: around
          }
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
      SUPPORTED_METHODS.each do |method|
        nice_method = method.downcase.to_sym
        define_method nice_method do |name_or_path = nil, path_or_name = nil, **hooks, &block|
          build_route(method, name_or_path, path_or_name, **hooks, &block)
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
        make_child(name, nil, definable: definable, **hooks, &block)
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
      def namespace(name_or_path = nil, path_or_name, **hooks, &block)
        # TODO: support regex path
        args  = Aargv.normalize([name_or_path, path_or_name], name: Symbol, path: String)
        name, path = args.values_at(:name, :path)
        make_child(name, path, definable: definable, **hooks, &block)
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
      def template(name, &block)
        templates[name] = block
      end

      # Expands a defined route template, or raises +NameError+.
      #
      # @see template
      #
      # @api public
      def expand(name, *args, **hooks, &block)
        make_child(*args, definable: definable, **hooks).expand_within(name, &block)
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
        if router = find_router(names)
          if expanding?
            router = router.make_child(self.name, self.path, **self.hooks)
            router.expand_within(@expansion.name, &block)
          else
            router.make_child(self.name, self.path, **self.hooks, &block)
          end
        else
          raise NameError, "Unknown router `#{names.first}'"
        end
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
        if expanding? && (method, route = @expansion.find_route(name))
          build_route(method, route.name, route.path, **hooks, &block)
        else
          expand(name, *args, **hooks, &block)
        end
      end

      # Redefine new so that we can have template parts named new.
      #
      # @api private
      def new(*args, &block)
        if expanding?
          method_missing(:new, *args, &block)
        else
          super
        end
      end

      # TODO: rethink this a bit once we can define groups / namespaces in a template
      # this feels kind of wrong, in that it's used as the path when building
      # @api private
      attr_accessor :nested_path

      # @api private
      attr_reader :name, :path, :definable

      # @api private
      def hooks
        @hooks ||= {
          before: [], after: [], around: []
        }
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
      def inherited(klass)
        path = self.path
        nested_path = self.nested_path
        hooks = self.hooks.deep_dup
        templates = self.templates.deep_dup
        handlers = self.handlers.deep_dup
        exceptions = self.exceptions.deep_dup

        klass.class_eval do
          @path = path
          @nested_path = nested_path
          @hooks = hooks
          @templates = templates
          @handlers = handlers
          @exceptions = exceptions

          DEFAULT_EXTENSIONS.each do |extension|
            include(Kernel.const_get(extension))
          end
        end
      end

      # @api private
      def path_to(*names, **params)
        combined_name = names.join("_").to_sym
        if found_route = routes.values.flatten.find { |route| route.name == combined_name }
          if found_route.parameterized?
            return found_route.populated_path(**params)
          else
            return found_route.path
          end
        end

        children.reject { |router_to_match|
          router_to_match.name.nil? || router_to_match.name != names.first
        }.each do |matched_router|
          if path = matched_router.path_to(*names[1..-1], **params)
            return path
          end
        end

        nil
      end

      # @api private
      def make(name_or_path = nil, path_or_name = nil, before: [], after: [], around: [], definable: nil, &block)
        # TODO: support regex path
        args  = Aargv.normalize([name_or_path, path_or_name], name: Symbol, path: String)
        name, path = args.values_at(:name, :path)

        klass = Class.new(self)

        if name
          # TODO: snakecase to camelcase
          klass_name = "#{name.to_s.capitalize}Router"
          unless Object.const_defined?(klass_name)
            klass = Object.const_set(klass_name, klass)
          end
        end

        klass.class_eval do
          @name = name
          @path = path
          @nested_path = nil
          @definable = definable
          @hooks = compile_hooks(
            before: before,
            after: after,
            around: around
          )

          class_eval(&block) if block
        end

        klass
      end

      # @api private
      def make_child(name = nil, path = nil, **hooks, &block)
        router = make(name, full_path(path, prefix: @nested_path || self.path), definable: definable, **hooks, &block)
        children << router
        router
      end

      # @api private
      def routes
        @routes ||= SUPPORTED_METHODS.each_with_object({}) do |method, routes_hash|
          routes_hash[method] = []
        end
      end

      # @api private
      def call(path, method, params, type, context: nil)
        # normalize and strip the format off the end
        # TODO: we need some path helpers for these things
        path = String.normalize_path(path).split(".")[0]

        children.each do |child_router|
          return true if child_router.call(path, method, params, type, context: context) === true
        end

        routes[method].each do |route|
          catch :reject do
            next unless route.match?(path, params, type)

            instance = self.new(context)
            context.current_router = instance
            route.call(context: instance)
            return true
          end
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
        hooks.each do |_, hooks_arr|
          hooks_arr.freeze
        end

        children.each do |child|
          child.freeze
        end

        routes.each do |_, routes_arr|
          routes_arr.each(&:freeze)
          routes_arr.freeze
        end

        path.freeze
        hooks.freeze
        children.freeze
        routes.freeze
        templates.freeze

        super
      end

      # @api private
      def exception_for_class(klass, exceptions: {})
        exceptions = self.exceptions.merge(exceptions)

        if exception = exceptions[klass]
          return exception
        end
      end

      # @api private
      def handler_for_code(code, handlers: {})
        handlers = self.handlers.merge(handlers)

        if handler = handlers[code]
          return handler
        end
      end

      # @api private
      def find_router(names, routers = known_routers)
        first_name = names.first.to_sym

        routers.each do |router|
          if router.name == first_name
            if names.length == 1
              return router
            else
              return find_router(names[1..-1], router.children)
            end
          else
            return find_router(names, router.children)
          end
        end

        nil
      end

      # @api private
      def known_routers
        routers = []
        routers.concat(children)
        routers.concat(definable.state[:router].instances)
        routers
      end

      # @api private
      def expand_within(name, &block)
        if template = templates[name]
          @expansion = Routing::Expansion.new(name, template, self, &block)
          class_eval(&block)
          @expansion = nil
        else
          raise NameError, "Unknown template `#{name}'"
        end
      end

      protected

      def build_route(method, name_or_path, path_or_name, **hooks, &block)
        args  = Aargv.normalize([name_or_path, path_or_name], name: Symbol, path: String, regex: Regexp)

        route = Routing::Route.new(
          name: args[:name],
          path: full_path(args[:path] || args[:regex]),
          hooks: compile_hooks(hooks || {}),
          &block
        )

        routes[method] << route
        route
      end

      def full_path(path_part, prefix: path)
        if prefix.is_a?(Regexp) || path_part.is_a?(Regexp)
          prefix = prefix.source if prefix.is_a?(Regexp)
          path_part = path_part.source if path_part.is_a?(Regexp)
          Regexp.new("^#{File.join(prefix.to_s, path_part.to_s)}$")
        else
          File.join(prefix.to_s, path_part.to_s)
        end
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
            route = route_to_merge.dup
            route.instance_variable_set(:@path, String.normalize_path(full_path(route_to_merge.path)))
            route
          })
        end
      end

      def merge_templates(templates_to_merge)
        templates.merge!(templates_to_merge)
      end

      def expanding?
        defined?(@expansion) && !@expansion.nil?
      end
    end
  end
end
