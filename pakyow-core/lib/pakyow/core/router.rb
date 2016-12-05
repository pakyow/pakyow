require "pakyow/support/aargv"
require "pakyow/support/array"

# TODO: group / namespace in templates

# TODO: formats
# TODO: within

module Pakyow
  # TODO:
  #   - the route being defined in context with logic
  #   - how to use routers (direct vs through an app)
  #   - how routes are defined at particular paths
  #     - and what types are supported
  #     - note that HEAD is not handled here
  #   - named routes and how they work with lookups
  #   - defined functions and how the can be used
  #   - using named functions as hooks
  #   - mention namespaces, groups, templates
  #     - point them to other docs inline
  #   - routing mixins and how they can be used
  class Router
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

    # Routing extensions that are automatically available in each router.
    #
    DEFAULT_EXTENSIONS = [
      "Pakyow::Routing::Extensions::Restful"
    ].freeze

    # TODO: rethink this a bit once we can define groups / namespaces in a template
    # this feels kind of wrong, in that it's used as the path when building
    attr_accessor :nested_path

    # @api private
    attr_reader :name, :path, :funcs, :hooks, :routes, :children, :templates

    # TODO: describe all the ways it can be initialized
    def initialize(name_or_path = nil, path_or_name = nil, before: [], after: [], around: [], &block)
      # TODO: support regex path
      args  = Aargv.normalize([name_or_path, path_or_name], name: Symbol, path: String)
      name, path = args.values_at(:name, :path)

      @name  = name
      @path  = path

      @hooks = {
        before: Array.ensure(before),
        after: Array.ensure(after),
        around: Array.ensure(around)
      }

      @funcs = {}
      @children = []
      @templates = {}

      @routes = SUPPORTED_METHODS.each_with_object({}) do |method, routes_hash|
        routes_hash[method] = []
      end

      DEFAULT_EXTENSIONS.each do |extension|
        extend Object.const_get(extension)
      end

      instance_eval(&block) if block_given?
    end

    # Creates a named function that can later be used as an endpoint
    # for a route or as a route hook.
    #
    def func(name, &block)
      if block_given?
        @funcs[name] = block
      else
        @funcs.fetch(name) {
          raise NameError, "Undefined func `#{name}` for Router"
        }
      end
    end

    # Creates a default route (synonmous with `get "/"`).
    #
    def default(func: nil, **hooks, &block)
      get :default, "/", func: func, **hooks, &block
    end

    SUPPORTED_METHODS.each do |method|
      nice_method = method.downcase.to_sym
      define_method nice_method do |name_or_path = nil, path_or_name = nil, func: nil, **hooks, &block|
        build_route(method, name_or_path, path_or_name, func: func, **hooks, &block)
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
    #   Pakyow::Router.new do
    #     func :foo do
    #       logger.info "foo"
    #     end
    #
    #     group :foo, before: [:foo] do
    #       func :bar do
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
    #   => "/foo/bar"
    #
    # @example Building a path to a route within an unnamed group:
    #   path :foo_baz
    #   => nil
    #
    #   path :baz
    #   => "/baz"
    #
    def group(name = nil, **hooks, &block)
      router = Router.new(name, **compile_hooks(hooks))
      router.instance_eval(&block)
      children << router
    end

    # Creates a group of routes and mounts them at a path, with an optional
    # name as well as hooks. A namespace behaves just like a group with
    # regard to path lookup and hook inheritance.
    #
    # @example Defining a namespace:
    #   Pakyow::Router.new do
    #     namespace :api, "/api" do
    #       func :auth do
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

      router = Router.new(name, full_path(path), **compile_hooks(hooks))
      router.instance_eval(&block)
      children << router
    end

    # TODO: rename to endpoint
    def path_to(*names, **params)
      first_name = names.first
      if route = routes.values.flatten.find { |route| route.name == first_name }
        if route.parameterized?
          return route.populated_path(**params)
        else
          return route.path
        end
      end

      children.reject { |router_to_match|
        router_to_match.name.nil? || router_to_match.name != first_name
      }.each do |matched_router|
        if path = matched_router.path_to(*names[1..-1], **params)
          return path
        end
      end
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
    # to define the resource template ({Routing::Extensions::Resource}).
    #
    # @example Defining a template:
    #   Pakyow::Router.new do
    #     template :talkback do
    #       get :hello, "/hello"
    #       get :goodbye, "/goodbye"
    #     end
    #   end
    #
    # @example Expanding a template:
    #
    #   Pakyow::Router.new do
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

    # TODO: flesh this out
    def expand
    end

    # TODO: call the `expand` method
    def method_missing(method, *args, **hooks, &block)
      if template = templates[method]
        args[1] = full_path(args[1] || "")
        expansion = Routing::Expansion.new(template, *args, **hooks, &block)
        children << expansion.router
      else
        raise NameError, "Unknown template `#{method}'"
      end
    end

    def call(path, method, request: nil, context: nil)
      path = String.normalize_path(path)

      routes[method].each do |route|
        catch :reject do
          next unless route.match?(path, request)
          route.call(context: context)
          return true
        end
      end

      children.each do |child_router|
        return true if child_router.call(path, method, request: request, context: context) === true
      end
    end

    # @api private
    def merge(router)
      merge_funcs(router.funcs)
      merge_hooks(router.hooks)
      merge_routes(router.routes)
      merge_templates(router.templates)
    end

    # api private
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
      funcs.freeze
      hooks.freeze
      children.freeze
      routes.freeze
      templates.freeze

      super
    end

    protected

    def build_route(method, name_or_path, path_or_name, func: nil, **hooks, &block)
      args  = Aargv.normalize([name_or_path, path_or_name], name: Symbol, path: String, regex: Regexp)
      block = func(func) if func

      route = Routing::Route.new(
        name: args[:name],
        path: full_path(args[:path] || args[:regex]),
        hooks: compile_hooks(hooks || {}),
        &block
      )

      routes[method] << route
      route
    end

    def full_path(path_part)
      path = @nested_path || @path
      if path.is_a?(Regexp) || path_part.is_a?(Regexp)
        Regexp.new("^#{File.join(path.to_s, path_part.to_s)}$")
      else
        File.join(path.to_s, path_part.to_s)
      end
    end

    def compile_hooks(hooks_to_compile)
      # TODO: seems weird that we'd call `combined_hooks` here
      combined = combined_hooks(hooks_to_compile)

      combined.each do |type, hooks|
        combined[type] = hooks.map { |hook|
          hook.is_a?(Proc) ? hook : func(hook)
        }
      end
    end

    def combined_hooks(hooks_to_combine)
      hooks.each_with_object({}) do |(type, hooks), combined|
        combined[type] = hooks.dup.concat(
          Array.ensure(hooks_to_combine[type] || [])
        ).uniq
      end
    end

    # TODO: move these merge funcs somewhere else
    def merge_funcs(funcs_to_merge)
      funcs.merge!(funcs_to_merge)
    end

    def merge_hooks(hooks_to_merge)
      hooks.each_pair do |type, hooks_of_type|
        hooks_of_type.concat(hooks_to_merge[type] || [])
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
  end
end
