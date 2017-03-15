module Pakyow
  # Processes a request received by an application.
  #
  # @api public
  class Controller
    include Support::Hookable
    known_events :process, :route, :error, :trigger

    # The current request (see {Request}).
    #
    # @api public
    attr_reader :request

    # The current response (see {Response}).
    #
    # @api public
    attr_reader :response

    # The app fulfilling the current request (see {App}).
    #
    # @api public
    attr_reader :app

    # @api private
    attr_reader :handlers, :exceptions, :current_router

    alias :req :request
    alias :res :response

    extend Forwardable

    # @!method logger
    #   @return the request's logger
    # @!method params
    #   @return the request's params (see {Request#params})
    # @!method session
    #   @return the request's session
    # @!method cookies
    #   @return the request's cookies (see {Request#cookies})
    def_delegators :request, :logger, :params, :session, :cookies

    # @!method config
    #   @return the config object
    def_delegators :app, :config

    # Tells the logger that an error occurred when processing a request.
    #
    before :error do
      logger.houston(req.error)
    end

    # Dups the cookies for comparison at the end of the request/response lifecycle.
    #
    before :process do
      @cookies = request.cookies.dup
    end

    # Handles setting and deleting cookies after a request is processed.
    #
    after :process do
      request.cookies.each_pair do |name, value|
        name = name.to_s

        # delete the cookie if the value has been set to nil
        response.delete_cookie(name) if value.nil?

        # cookie is already set with value, ignore
        next if @cookies.include?(name) && @cookies[name] == value

        # set cookie with defaults
        response.set_cookie(name, {
          path: config.cookies.path,
          expires: Time.now + config.cookies.expiry,
          value: value
        })
      end

      # delete cookies that were deleted from the request
      (@cookies.keys - request.cookies.keys).each do |name|
        response.delete_cookie(name)
      end
    end

    class << self
      # @api private
      def process(env, app)
        instance = self.new(env, app)
        instance.process
      end
    end

    # @api private
    def initialize(env, app)
      @request = Request.new(env)
      @response = Response.new
      @app = app

      @handlers = {}
      @exceptions = {}
    end

    # @api private
    def process
      hook_around :process do
        catch :halt do
          if app.config.routing.enabled
            hook_around :route do
              app.state_for(:router).each do |router|
                @current_router = router
                @found = router.call(
                  request.env[Rack::PATH_INFO],
                  request.env[Rack::REQUEST_METHOD],
                  request.params,
                  context: self
                )

                break if found?
              end
            end
          end

          trigger(404) unless found?
        end
      end
    rescue StandardError => error
      request.error = error

      catch :halt do
        if failed_router
          if status = failed_router.exception(error.class, context: self, handlers: handlers, exceptions: exceptions)
            response.status = status
            return
          end
        end

        hook_around :error do
          trigger(500)
        end
      end
    ensure
      return response.finish
    end

    # Registers an error handler used for the lifecycle of the current request.
    #
    # @example Handling a status code:
    #   Pakyow::App.router do
    #     default do
    #       handle 500 do
    #         # handle 500 responses for this route
    #       end
    #     end
    #   end
    #
    # @example Handling a status code by name:
    #   Pakyow::App.router do
    #     default do
    #       handle :forbidden do
    #         # handle 403 responses for this route
    #       end
    #     end
    #   end
    #
    # @example Handling an exception:
    #   Pakyow::App.router do
    #     default do
    #       handle Sequel::NoMatchingRow, as: 404 do
    #         # handle missing records for this route
    #       end
    #     end
    #   end
    #
    # @api public
    def handle(name_exception_or_code, as: nil, &block)
      if !name_exception_or_code.is_a?(Integer) && name_exception_or_code.ancestors.include?(Exception)
        raise ArgumentError, "status code is required" if as.nil?
        exceptions[name_exception_or_code] = [Rack::Utils.status_code(as), block]
      else
        handlers[Rack::Utils.status_code(name_exception_or_code)] = block
      end
    end

    # Redirects to +location+ and immediately halts request processing.
    #
    # @param location [String] what url the request should be redirected to
    # @param as [Integer, Symbol] the status to redirect with
    #
    # @example Redirecting:
    #   Pakyow::App.router do
    #     default do
    #       redirect "/foo"
    #     end
    #   end
    #
    # @example Redirecting with a status code:
    #   Pakyow::App.router do
    #     default do
    #       redirect "/foo", as: 301
    #     end
    #   end
    #
    # @api public
    def redirect(location, as: 302)
      response.status = Rack::Utils.status_code(as)
      response["Location"] = app.router.path(location)
      halt
    end

    # Reroutes the request to a different location. Instead of an http redirect,
    # the request will continued to be handled in the current request lifecycle.
    #
    # @param location [String] what url the request should be rerouted to
    # @param method [Symbol] the http method to reroute as
    #
    # @example
    #   Pakyow::App.resource :post, "/posts" do
    #     edit do
    #       @post ||= find_post_by_id(params[:post_id])
    #
    #       # render the form for @post
    #     end
    #
    #     update do
    #       if post_fails_to_create
    #         @post = failed_post_object
    #         reroute path(:post_edit, post_id: @post.id), method: :get
    #       end
    #     end
    #   end
    #
    # @api public
    def reroute(location, method: request.method)
      # TODO: a lot of the complexity in this object is due to rerouting
      # perhaps we can simplify things by creating a new request object
      # and providing access to the previous request via `parent`

      request.setup(app.router.path(location), method)

      hook_around :route do
        app.state_for(:router).each do |router|
          router.reroute(request)
        end
      end
    end

    # Sends a file or other data in the response.
    #
    # Accepts data as a +String+ or  +IO+ object. When passed a +File+ object,
    # the mime type will be determined automatically.
    #
    # @example Sending data:
    #   Pakyow::App.router do
    #     default do
    #       send "foo", type: "text/plain"
    #     end
    #   end
    #
    # @example Sending a file:
    #   Pakyow::App.router do
    #     default do
    #       filename = "foo.txt"
    #       send File.open(filename), name: filename
    #     end
    #   end
    #
    # @api public
    def send(file_or_data, type: nil, name: nil)
      if file_or_data.is_a?(IO) || file_or_data.is_a?(StringIO)
        data = file_or_data

        if file_or_data.is_a?(File)
          # auto set type based on file type
          type ||= Rack::Mime.mime_type(File.extname(file_or_data.path))
        end
      elsif file_or_data.is_a?(String)
        data = StringIO.new(file_or_data)
      else
        raise ArgumentError, "Expected an IO or String object"
      end

      response.body = data
      response["Content-Type"] = type if type
      response["Content-disposition"] = "attachment; filename=#{name}" if name
      halt
    end

    # Calls the handler for a particular http status code.
    #
    # @api public
    def trigger(name_or_code)
      code = Rack::Utils.status_code(name_or_code)
      response.status = code

      hook_around :trigger do
        app.state_for(:router).each do |router|
          break if router.trigger(code, context: self, handlers: handlers)
        end
      end
    end

    # Conveniently builds and returns the path to a particular route.
    #
    # @example Build the path to the +new+ route within the +post+ group:
    #   path(:post_new)
    #   # => "/posts/new"
    #
    # @example Build the path providing a value for +post_id+:
    #   path(:post_edit, post_id: 1)
    #   # => "/posts/1/edit"
    #
    # @api public
    def path(name, **params)
      path_to(*name.to_s.split("_").map(&:to_sym), **params)
    end

    # Builds and returns the path to a particular route.
    #
    # @example Build the path to the +new+ route within the +post+ group:
    #   path_to(:post, :new)
    #   # => "/posts/new"
    #
    # @example Build the path providing a value for +post_id+:
    #   path_to(:post, :edit, post_id: 1)
    #   # => "/posts/1/edit"
    #
    # @api public
    def path_to(*names, **params)
      app.router.reject { |router_to_match|
        router_to_match.name.nil? || router_to_match.name != names.first
      }.each do |matched_router|
        if path = matched_router.path_to(*names[1..-1], **params)
          return path
        end
      end
    end

    # Halts request processing, immediately returning the response.
    #
    # @api public
    def halt
      throw :halt, response
    end

    protected

    # @api private
    def reject
      throw :reject
    end

    # @api private
    def found?
      @found == true
    end

    # @api private
    def failed_router
      !found? && current_router
    end
  end
end
