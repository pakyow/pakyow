module Pakyow
  # TODO: document
  class Controller
    class << self
      def process(env, app)
        instance = self.new(env, app)
        instance.process
      end
    end
    
    include Support::Hookable
    known_events :process, :route, :error, :trigger
    
    attr_reader :request, :response, :app, :handlers, :exceptions

    alias :req :request
    alias :res :response
    
    extend Forwardable
    def_delegators :@request, :logger, :params, :session, :cookies

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
    
    def initialize(env, app)
      @request = Request.new(env)
      @response = Response.new
      @app = app
      
      @handlers = {}
      @exceptions = {}
    end
    
    def process
      hook_around :process do
        catch :halt do
          hook_around :route do
            app.state_for(:router).each do |router|
              @found = router.call(
                request.env[Rack::PATH_INFO],
                request.env[Rack::REQUEST_METHOD],
                request.params,
                context: self
              )

              break if found?
            end
          end

          trigger(404) unless found?
        end
      end
    rescue StandardError => error
      request.error = error

      catch :halt do
        app.state_for(:router).each do |router|
          if status = router.exception(error.class, context: self, handlers: handlers, exceptions: exceptions)
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
    
    def handle(name_exception_or_code, as: nil, &block)
      if !name_exception_or_code.is_a?(Integer) && name_exception_or_code.ancestors.include?(Exception)
        raise ArgumentError, "status code is required" if as.nil?
        exceptions[name_exception_or_code] = [Rack::Utils.status_code(as), block]
      else
        handlers[Rack::Utils.status_code(name_or_code)] = block
      end
    end

    protected

    # Redirects to location (immediately).
    #
    def redirect(location, name_or_code: 302)
      response.status = Rack::Utils.status_code(name_or_code)
      response["Location"] = app.router.path(location)
      halt
    end

    # Routes the request to different logic.
    #
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

    # Sends data in the response (immediately). Accepts a string of data or a File,
    # mime-type (auto-detected; defaults to octet-stream), and optional file name.
    #
    # If a File, mime type will be guessed. Otherwise mime type and file name will
    # default to whatever is set in the response.
    #
    def send(file_or_data, type: nil, as: nil)
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
      response["Content-disposition"] = "attachment; filename=#{as}" if as
      halt
    end

    def trigger(name_or_code)
      code = Rack::Utils.status_code(name_or_code)
      response.status = code

      hook_around :trigger do
        app.state_for(:router).each do |router|
          break if router.trigger(code, context: self, handlers: handlers)
        end
      end
    end
    
    def path(name, **params)
      path_to(*name.to_s.split("_").map(&:to_sym), **params)
    end

    def path_to(*names, **params)
      app.router.reject { |router_to_match|
        router_to_match.name.nil? || router_to_match.name != names.first
      }.each do |matched_router|
        if path = matched_router.path_to(*names[1..-1], **params)
          return path
        end
      end
    end
    
    # Interrupts the application and returns response immediately.
    #
    def halt
      throw :halt, response
    end
    
    # @api private
    def reject
      throw :reject
    end
    
    # @api private
    def found?
      @found == true
    end
  end
end
