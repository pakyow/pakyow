module Pakyow
  class Application
    class << self
      attr_accessor :core_proc, :middleware_proc, :middlewares, :configurations

      # Sets the path to the application file so it can be reloaded later.
      #
      def inherited(subclass)
        Pakyow::Configuration::App.application_path = StringUtils.parse_path_from_caller(caller[0])
      end

      # Runs the application. Accepts the environment(s) to run, for example:
      # run(:development)
      # run([:development, :staging])
      #
      def run(*args)
        return if running?

        @running = true
        self.builder.run(self.prepare(args))
        detect_handler.run(builder, :Host => Pakyow::Configuration::Base.server.host, :Port => Pakyow::Configuration::Base.server.port) do |server|
          trap(:INT)  { stop(server) }
          trap(:TERM) { stop(server) }
        end
      end

      # Stages the application. Everything is loaded but the application is
      # not started. Accepts the same arguments as #run.
      #
      def stage(*args)
        return if staged?
        @staged = true
        prepare(args)
      end

      def builder
        @builder ||= Rack::Builder.new
      end

      def prepared?
        @prepared
      end

      # Returns true if the application is running.
      #
      def running?
        @running
      end

      # Returns true if the application is staged.
      #
      def staged?
        @staged
      end

      # Convenience method for base configuration class.
      #
      def config
        Pakyow::Configuration::Base
      end

      # Creates configuration for a particular environment. Example:
      # configure(:development) { app.auto_reload = true }
      #
      def configure(environment, &block)
        self.configurations ||= {}
        self.configurations[environment] = block
      end

      # The block that stores routes, handlers, and hooks.
      #
      def core(&block)
        self.core_proc = block
      end

      # The block that stores presenter related things.
      #
      def presenter(&block)
        Configuration::Base.app.presenter.proc = block
      end

      def middleware(&block)
        self.middleware_proc = block
      end
      
      def before(step, middlewares)
        middlewares = [middlewares] unless middlewares.is_a?(Array)
        step = step.to_sym

        self.middlewares ||= {}
        self.middlewares[step] ||= {}
        (self.middlewares[step][:before] ||= []).concat(middlewares)
      end
      
      def after(step, middlewares)
        middlewares = [middlewares] unless middlewares.is_a?(Array)
        step = step.to_sym

        self.middlewares ||= {}
        self.middlewares[step] ||= {}
        (self.middlewares[step][:after] ||= []).concat(middlewares)
      end

      def use(step, type, builder)
        return unless self.middlewares
        return unless self.middlewares[step]
        return unless self.middlewares[step][type]

        self.middlewares[step][type].each { |m|
          builder.use(m)
        }
      end
      

      protected

      # Prepares the application for running or staging and returns an instance
      # of the application.
      def prepare(args)
        cfgs = args.empty? || args.first.nil? ? [Configuration::Base.app.default_environment] : args
        self.load_config(cfgs)
        return if prepared?

        self.builder.use(Rack::MethodOverride)

        self.builder.use(Pakyow::Middleware::Setup)

        #TODO possibly deprecate
        self.builder.instance_eval(&self.middleware_proc) if self.middleware_proc
        
        self.builder.use(Pakyow::Middleware::Static)      if Configuration::Base.app.static
        self.builder.use(Pakyow::Middleware::Logger)      if Configuration::Base.app.log
        self.builder.use(Pakyow::Middleware::Reloader)    if Configuration::Base.app.auto_reload
        
        if Configuration::Base.app.presenter
          self.use(:presentation, :before, self.builder)
          self.builder.use(Pakyow::Middleware::Presenter)   
          self.use(:presentation, :after, self.builder)
        end
        
        unless Configuration::Base.app.ignore_routes
          self.use(:routing, :before, self.builder)
          self.builder.use(Pakyow::Middleware::Router)
          self.use(:routing, :after, self.builder)
        end

        self.builder.use(Pakyow::Middleware::NotFound)    # always
        
        @prepared = true

        $:.unshift(Dir.pwd) unless $:.include? Dir.pwd
        return self.new(cfgs.first)
      end

      def load_config(args)
        if self.configurations
          args << Configuration::Base.app.default_environment if args.empty?
          args.each do |env|
            next unless config = self.configurations[env.to_sym]
            Configuration::Base.instance_eval(&config)
          end
        end
      end

      def detect_handler
        handlers = ['thin', 'mongrel', 'webrick']
        handlers.unshift(Configuration::Base.server.handler) if Configuration::Base.server.handler
        
        handlers.each do |handler|
          begin
            return Rack::Handler.get(handler)
          rescue LoadError
          rescue NameError
          end
        end
      end

      def stop(server)
        if server.respond_to?('stop!')
          server.stop!
        elsif server.respond_to?('stop')
          server.stop
        else
          # exit ungracefully if necessary...
          Process.exit!
        end
      end
    end

    include Helpers

    attr_accessor :request, :response, :presenter, :router, :env

    def initialize(primary_env)
      @env = primary_env
      Pakyow.app = self

      Pakyow.app.presenter = Configuration::Base.app.presenter.instance if Configuration::Base.app.presenter
            
      # Load application files
      load_app(false)

      # Prepare for logging
      Log.reopen
    end

    def setup_rr(env)
      self.request = Request.new(env)
      self.response = Response.new

      # response is needed before setting up request
      self.request.setup
    end

    # Called on every request.
    #
    def call(env)
      finish
    end

    # This is NOT a useless method, it's a part of the external api
    def reload
      load_app
    end


    # APP ACTIONS

    # Interrupts the application and returns response immediately.
    #
    def halt
      throw :halt, response
    end

    # Routes the request to different logic.
    #
    def reroute(path, method = nil)
      self.request.setup(path, method)

      begin
        # caught by other middleware (e.g. presenter) that does something with the
        # new request then hands it back down to the router
        throw :rerouted, request
      rescue ArgumentError
        # nobody caught it, so tell the router to reroute
        app.router.reroute!(request)
      end
    end

    # Sends data in the response (immediately). Accepts a string of data or a File,
    # mime-type (auto-detected; defaults to octet-stream), and optional file name.
    #
    # If a File, mime type will be guessed. Otherwise mime type and file name will
    # default to whatever is set in the response.
    #
    def send(file_or_data, type = nil, send_as = nil)
      case file_or_data.class
      when File
        data = File.open(path, "r").each_line { |line| data << line }

        # auto set type based on file type
        type = Rack::Mime.mime_type("." + StringUtils.split_at_last_dot(File.path))[1]
      else
        data = file_or_data
      end

      headers = {}
      headers["Content-Type"]         = type if type
      headers["Content-disposition"]  = "attachment; filename=#{send_as}" if send_as

      app.response = Rack::Response.new(data, response.status, response.header.merge(headers))
      halt
    end

    # Redirects to location (immediately).
    #
    def redirect(location, status_code = 302)
      headers = response ? response.header : {}
      headers = headers.merge({'Location' => location})

      app.response = Rack::Response.new('', status_code, headers)
      halt
    end

    def handle(name_or_code)
      app.router.handle!(name_or_code, true)
    end

    # Convenience method for defining routes outside of core block.
    #
    def routes(set_name = :default, &block)
      @router.set(set_name, &block)
    end

    protected

    #TODO need configuration options for cookies (plus ability to override for each?)
    def set_cookies
      if self.request.cookies && self.request.cookies != {}
        self.request.cookies.each do |key, value|
          if value.nil?
            self.response.set_cookie(key, {:path => '/', :expires => Time.now + 604800 * -1 }.merge({:value => value}))
          elsif value.is_a?(Hash)
            self.response.set_cookie(key, {:path => '/', :expires => Time.now + 604800}.merge(value))
          else
            self.response.set_cookie(key, {:path => '/', :expires => Time.now + 604800}.merge({:value => value}))
          end
        end
      end
    end

    # Reloads all application files in application_path and presenter (if specified).
    #
    def load_app(reload_app = true)
      load(Configuration::App.application_path) if reload_app

      @router = Router.instance

      @loader = Loader.new unless @loader
      @loader.load_from_path(Configuration::Base.app.src_dir)

      self.load_core
      self.presenter.load if self.presenter
    end

    # Evaluates core_proc
    #
    def load_core
      return unless self.class.core_proc
      @router.set(:default, &self.class.core_proc)
    end
    
    # Send the response and cleanup.
    #
    #TODO remove exclamation
    def finish
      set_cookies
      self.response.finish
    end

  end
end
