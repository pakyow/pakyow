# frozen_string_literal: true

require "forwardable"
require "uri"

require "pakyow/support/aargv"
require "pakyow/support/handleable"
require "pakyow/support/hookable"
require "pakyow/support/pipeline"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/connection/statuses"

require "pakyow/handleable/behavior/statuses"

require_relative "../security/errors"

require_relative "route"

require_relative "controller/behavior/error_handling"
require_relative "controller/behavior/param_verification"

module Pakyow
  module Routing
    # Executes code for particular requests. For example:
    #
    #   Pakyow::Application.controller do
    #     get "/" do
    #       # called for GET / requests
    #     end
    #   end
    #
    # A +Class+ is created dynamically for each defined controller. When matched, a route is called in
    # context of its controller. This means that any method defined in a controller is available to be
    # called from within a route. For example:
    #
    #   Pakyow::Application.controller do
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
    #   Pakyow::Application.controller do
    #     include AuthHelpers
    #
    #     get :foo, "/foo" do
    #       current_user
    #     end
    #   end
    #
    # See {Application.controller} for more details on defining controllers.
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
    # = Reusing logic with actions
    #
    # Methods can be defined as additional actions for a route. For example:
    #
    #   Pakyow::Application.controller do
    #     action :called_before
    #
    #     def called_before
    #       ...
    #     end
    #
    #     get :foo, "/foo" do
    #       ...
    #     end
    #   end
    #
    # = Extending controllers
    #
    # Extensions can be defined and used to add shared routes to one or more controllers.
    # See {Routing::Extension}.
    #
    # = Other routing features
    #
    # More advanced route features are available, including groups, namespaces, and templates. See
    # {group}, {namespace}, and {template}.
    #
    # = Controller subclasses
    #
    # It's possible to work with controllers outside of Pakyow's DSL. For example:
    #
    #   class FooController < Pakyow::Routing::Controller("/foo")
    #     default do
    #       # available at GET /foo
    #     end
    #   end
    #
    #   Pakyow::Application.controller << FooController
    #
    # = Custom matchers
    #
    # Controllers and routes can be defined with a matcher rather than a path. The matcher could be a
    # +Regexp+ or any custom object that implements +match?+. For example:
    #
    #   class CustomMatcher
    #     def match?(path)
    #       path == "/custom"
    #     end
    #   end
    #
    #   Pakyow::Application.controller CustomMatcher.new do
    #   end
    #
    # Custom matchers can also make data available in +params+ by implementing +match+ and returning
    # an object that implements +named_captures+. For example:
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
    #   Pakyow::Application.controller CustomMatcher.new do
    #   end
    #
    class Controller
      using Support::DeepDup
      extend Support::ClassState

      include Support::Hookable
      events :dispatch

      include Support::Pipeline

      using Support::Refinements::String::Normalization

      include Support::Handleable
      include Handleable::Behavior::Statuses

      include Routing::Behavior::ErrorHandling
      include Routing::Behavior::ParamVerification

      METHOD_GET    = :get
      METHOD_HEAD   = :head
      METHOD_POST   = :post
      METHOD_PUT    = :put
      METHOD_PATCH  = :patch
      METHOD_DELETE = :delete

      DEFINABLE_HTTP_METHODS = [
        METHOD_GET,
        METHOD_POST,
        METHOD_PUT,
        METHOD_PATCH,
        METHOD_DELETE
      ].freeze

      CONTENT_DISPOSITION = "Content-Disposition".freeze

      require "pakyow/routing/expansion"

      # Controllers must be initialized with an argument, even though the argument
      # isn't actually used. This is a side-effect of allowing templates to define
      # a route named "new". In the expansion, we differentiate between expanding
      # and initializing by whether an argument is present, which works because
      # arguments aren't passed for expansions.
      #
      def initialize(app)
        @children = self.class.children.map { |child|
          child.new(app)
        }

        self.class.routes.values.flatten.each do |route|
          route.pipeline = self.class.__pipeline.dup

          self.class.limit_by_route[route.name].to_a.each do |action|
            route.pipeline.actions << action
          end

          route.pipeline.actions.delete_if do |action|
            self.class.global_skips.to_a.include?(action.name) ||
              self.class.skips_by_route[route.name].to_a.include?(action.name)
          end

          route.pipeline.action(:dispatch)
        end
      end

      def call(connection, request_path = connection.path)
        request_method = connection.method
        if request_method == METHOD_HEAD
          request_method = METHOD_GET
        end

        matcher = self.class.matcher
        if match = matcher.match(request_path)
          match_data = match.named_captures
          connection.params.merge!(match_data)

          if matcher.is_a?(Regexp)
            request_path = String.normalize_path(request_path.sub(matcher, ""))
          end

          @children.each do |child_controller|
            child_controller.call(connection, request_path)
            return if connection.halted?
          end

          unless connection.halted?
            self.class.routes[request_method].to_a.each do |route|
              if route_match = route.match(request_path)
                connection.params.merge!(route_match.named_captures)

                connection.set(
                  :__endpoint_path,
                  String.normalize_path(
                    File.join(
                      self.class.path_to_self.to_s, route.path.to_s
                    )
                  )
                )

                connection.set(:__endpoint_name, route.name)

                dup.call_route(connection, route)
              end

              return if connection.halted?
            end
          end
        end
      end

      # @api private
      def call_route(connection, route)
        @connection, @route = connection, route

        handling(connection: connection) do
          @route.pipeline.call(self, connection)
        rescue => error
          connection.error = error
          Pakyow.houston(error)
          raise error
        end

        halt unless connection.rejected?
      end

      # @api private
      def dispatch
        halted = false
        performing :dispatch do
          halted = catch :halt do
            @route.call(self)
          end
        end

        # Catching the halt then re-halting lets us call after dispatch hooks in non-error cases.
        #
        halt if halted
      end

      # Redirects to +location+ and immediately halts request processing.
      #
      # @param location [String] what url the request should be redirected to
      # @param as [Integer, Symbol] the status to redirect with
      # @param trusted [Boolean] whether or not the location is trusted
      #
      # @example Redirecting:
      #   Pakyow::Application.controller do
      #     default do
      #       redirect "/foo"
      #     end
      #   end
      #
      # @example Redirecting with a status code:
      #   Pakyow::Application.controller do
      #     default do
      #       redirect "/foo", as: 301
      #     end
      #   end
      #
      # @example Redirecting to a remote location:
      #   Pakyow::Application.controller do
      #     default do
      #       redirect "http://foo.com/bar", trusted: true
      #     end
      #   end
      #
      def redirect(location, as: 302, trusted: false, **params)
        location = case location
        when Symbol
          app.endpoints.path(location, **params)
        else
          location
        end

        if trusted || URI(location).host.nil?
          @connection.status = Connection::Statuses.code(as)
          @connection.set_header("location", location)
          halt
        else
          raise Security::InsecureRedirect.new_with_message(
            location: location
          )
        end
      end

      # Reroutes the request to a different location. Instead of an http redirect, the request will
      # continued to be handled in the current request lifecycle.
      #
      # @param location [String] what url the request should be rerouted to
      # @param method [Symbol] the http method to reroute as
      #
      # @example
      #   Pakyow::Application.resource :posts, "/posts" do
      #     edit do
      #       @post ||= find_post_by_id(params[:post_id])
      #
      #       # render the form for @post
      #     end
      #
      #     update do
      #       if post_fails_to_create
      #         @post = failed_post_object
      #         reroute path(:posts_edit, post_id: @post.id), method: :get
      #       end
      #     end
      #   end
      #
      def reroute(location, method: connection.method, as: nil, **params)
        connection = @connection.__getobj__

        # Make sure the endpoint is set.
        #
        connection.endpoint

        connection.instance_variable_set(:@method, method)
        connection.instance_variable_set(:@path, location.is_a?(Symbol) ? app.endpoints.path(location, **params) : location)

        # Change the response status, if set.
        #
        connection.status = Connection::Statuses.code(as) if as

        @connection.set(:__endpoint_path, nil)
        @connection.set(:__endpoint_name, nil)
        @connection.remove_instance_variable(:@path)

        app.perform(@connection); halt
      end

      # Responds to a specific request format.
      #
      # The +Content-Type+ header will be set on the response based on the format that is being
      # responded to.
      #
      # After yielding, request processing will be halted.
      #
      # @example
      #   Pakyow::Application.controller do
      #     get "/foo.txt|html" do
      #       respond_to :txt do
      #         send "foo"
      #       end
      #
      #       # do something for html format
      #     end
      #   end
      #
      def respond_to(format)
        return unless @connection.format == format.to_sym
        @connection.format = format
        yield
        halt
      end

      DEFAULT_SEND_TYPE = "application/octet-stream".freeze

      # Sends a file or other data in the response.
      #
      # Accepts data as a +String+ or +IO+ object. When passed a +File+ object, the mime type will be
      # determined automatically. The type can be set explicitly with the +type+ option.
      #
      # Passing +name+ sets the +Content-Disposition+ header to "attachment". Otherwise, the
      # disposition will be set to "inline".
      #
      # @example Sending data:
      #   Pakyow::Application.controller do
      #     default do
      #       send "foo", type: "text/plain"
      #     end
      #   end
      #
      # @example Sending a file:
      #   Pakyow::Application.controller do
      #     default do
      #       filename = "foo.txt"
      #       send File.open(filename), name: filename
      #     end
      #   end
      #
      def send(file_or_data, type: nil, name: nil)
        if file_or_data.is_a?(IO) || file_or_data.is_a?(StringIO)
          data = file_or_data

          if file_or_data.is_a?(File)
            type ||= MiniMime.lookup_by_filename(file_or_data.path)&.content_type.to_s
          end

          @connection.set_header("content-type", type || DEFAULT_SEND_TYPE)
        elsif file_or_data.is_a?(String)
          @connection.set_header("content-type", type) if type
          data = StringIO.new(file_or_data)
        else
          raise ArgumentError, "expected an IO or String object"
        end

        @connection.set_header(CONTENT_DISPOSITION, name ? "attachment; filename=#{name}" : "inline")
        halt(data)
      end

      # Halts request processing, immediately returning the response.
      #
      # The response body will be set to +body+ prior to halting (if it's a non-nil value).
      #
      def halt(body = nil, status: nil)
        @connection.body = body if body
        @connection.status = Connection::Statuses.code(status) if status
        @connection.halt
      end

      # Rejects the request, calling the next matching route.
      #
      def reject
        @connection.reject
      end

      class_state :templates, default: {}, inheritable: true
      class_state :expansions, default: [], inheritable: false
      class_state :routes, default: DEFINABLE_HTTP_METHODS.each_with_object({}) { |supported_method, routes_hash|
                                      routes_hash[supported_method] = []
                                    }, inheritable: false

      class_state :limit_by_route, default: {}, inheritable: false
      class_state :skips_by_route, default: {}, inheritable: false

      # Global rules should be inherited by children, but route-specific rules
      # shouldn't be since they refer to a specific route in the current context.
      #
      class_state :global_skips, default: [], inheritable: true

      class << self
        def action(name, only: [], skip: [], &block)
          @__pipeline.actions.delete_if do |action|
            action.name == name
          end

          if only.any?
            only.each do |route_name|
              (@limit_by_route[route_name] ||= []) << Support::Pipeline::Action.new(self, name, &block)
            end
          else
            super(name, &block)
          end

          skip.each do |route_name|
            (@skips_by_route[route_name] ||= []) << name
          end
        end

        def skip(name, only: [])
          if only.empty?
            @global_skips << name
          else
            only.each do |route_name|
              (@skips_by_route[route_name] ||= []) << name
            end
          end
        end

        # Conveniently define defaults when subclassing +Pakyow::Routing::Controller+.
        #
        # @example
        #   class MyController < Pakyow::Routing::Controller("/foo")
        #     # more routes here
        #   end
        #
        # rubocop:disable Naming/MethodName
        def Controller(matcher)
          make(matcher)
        end
        # rubocop:enabled Naming/MethodName

        # Create a default route. Shorthand for +get "/"+.
        #
        # @see get
        #
        def default(&block)
          get :default, "/", &block
        end

        # @!method get
        #   Create a route that matches +GET+ requests at +path+. For example:
        #
        #     Pakyow::Application.controller do
        #       get "/foo" do
        #         # do something
        #       end
        #     end
        #
        #   Routes can be named, making them available for path building via {Controller#path}. For
        #   example:
        #
        #     Pakyow::Application.controller do
        #       get :foo, "/foo" do
        #         # do something
        #       end
        #     end
        #
        # @!method post
        #   Create a route that matches +POST+ requests at +path+.
        #
        #   @see get
        #
        # @!method put
        #   Create a route that matches +PUT+ requests at +path+.
        #
        #   @see get
        #
        # @!method patch
        #   Create a route that matches +PATCH+ requests at +path+.
        #
        #   @see get
        #
        # @!method delete
        #   Create a route that matches +DELETE+ requests at +path+.
        #
        #   @see get
        #
        DEFINABLE_HTTP_METHODS.each do |http_method|
          define_method http_method.downcase.to_sym do |name_or_matcher = nil, matcher_or_name = nil, &block|
            build_route(http_method, name_or_matcher, matcher_or_name, &block)
          end
        end

        # Creates a nested group of routes, with an optional name.
        #
        # Named groups make the routes available for path building. Paths to routes defined in unnamed
        # groups are referenced by the most direct parent group that is named.
        #
        # @example Defining a group:
        #   Pakyow::Application.controller do
        #
        #     def foo
        #       logger.info "foo"
        #     end
        #
        #     group :foo do
        #       action :foo
        #       action :bar
        #
        #       def bar
        #         logger.info "bar"
        #       end
        #
        #       get :bar, "/bar" do
        #         # "foo" and "bar" have both been logged
        #         send "foo.bar"
        #       end
        #     end
        #
        #     group do
        #       action :foo
        #
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
        def group(name = nil, **kwargs, &block)
          define(name, nil, **kwargs, &block)
        end

        # Creates a group of routes and mounts them at a path, with an optional name. A namespace
        # behaves just like a group with regard to path lookup and action inheritance.
        #
        # @example Defining a namespace:
        #   Pakyow::Application.controller do
        #     namespace :api, "/api" do
        #       def auth
        #         handle 401 unless authed?
        #       end
        #
        #       namespace :project, "/projects" do
        #         get :list, "/" do
        #           # route is accessible via 'GET /api/projects'
        #           send projects.to_json
        #         end
        #       end
        #     end
        #   end
        #
        def namespace(*args, **kwargs, &block)
          controller_name, matcher = parse_name_and_matcher_from_args(*args)
          define(controller_name, matcher, **kwargs, &block)
        end

        # Creates a route template with a name and block. The block is evaluated within a
        # {Routing::Expansion} instance when / if it is later expanded at some endpoint (creating a
        # namespace).
        #
        # Route templates are used to define a scaffold of default routes that will later be expanded
        # at some path. During expansion, the scaffolded routes are also mapped to routing logic.
        #
        # Because routes can be referenced by name during expansion, route templates provide a way to
        # create a domain-specific-language, or DSL, around a routing concern. This is used within
        # Pakyow itself to define the resource template ({Routing::Extension::Resource}).
        #
        # @example Defining a template:
        #   Pakyow::Application.controller do
        #     template :talkback do
        #       get :hello, "/hello"
        #       get :goodbye, "/goodbye"
        #     end
        #   end
        #
        # @example Expanding a template:
        #
        #   Pakyow::Application.controller do
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
        def expand(name, *args, **options, &block)
          define(*args).expand_within(name, **options, &block)
        end

        # Attempts to find and expand a template, avoiding the need to call {expand} explicitly. For
        # example, these calls are identical:
        #
        #   Pakyow::Application.controller do
        #     resource :posts, "/posts" do
        #     end
        #
        #     expand :resource, :posts, "/posts" do
        #     end
        #   end
        #
        def method_missing(name, *args, &block)
          if templates.include?(name)
            expand(name, *args, &block)
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_private = false)
          templates.include?(method_name) || super
        end

        # @api private
        attr_reader :path, :matcher

        def path_to_self
          return path unless parent
          File.join(parent.path_to_self.to_s, path.to_s)
        end

        def name_of_self
          self_name = object_name&.name

          if parent
            # Ignore member and collection namespaces for endpoint building.
            #
            if self_name == :member || self_name == :collection
              self_name = nil
            end

            [parent.name_of_self, self_name].compact.join("_").to_sym
          else
            self_name
          end
        end

        # @api private
        def build_endpoints(endpoints)
          @routes.values.flatten.reject { |route| route.name.nil? }.each do |route|
            if route.name == :default && name_of_self
              # Register the endpoint without the default name for easier lookup.
              #
              endpoints.build(
                name: name_of_self,
                method: route.method,
                builder: Routing::Route::EndpointBuilder.new(
                  route: route, path: path_to_self
                )
              )
            end

            endpoints.build(
              name: [name_of_self, route.name].compact.join("_"),
              method: route.method,
              builder: Routing::Route::EndpointBuilder.new(
                route: route, path: path_to_self
              )
            )
          end

          children.each do |child|
            child.build_endpoints(endpoints)
          end
        end

        # @api private
        def expand_within(name, **options, &block)
          raise NameError, "unknown template `#{name}'" unless template = templates[name]
          Routing::Expansion.new(name, self, options, &template)
          class_eval(&block)
          self
        end

        # @api private
        def parse_name_and_matcher_from_args(name_or_matcher = nil, matcher_or_name = nil)
          return Support::Aargv.normalize(
            [name_or_matcher, matcher_or_name].compact, name: [Symbol, Support::ObjectName], matcher: Object
          ).values_at(:name, :matcher)
        end

        private def build_route(method, *args, &block)
          route_name, matcher = parse_name_and_matcher_from_args(*args)

          Routing::Route.new(matcher, name: route_name, method: method, &block).tap do |route|
            routes[method] << route
          end
        end
      end
    end
  end
end
