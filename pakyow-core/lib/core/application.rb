module Pakyow
  class Application
    class << self
      attr_accessor :routes_proc, :middleware_proc, :configurations, :error_handlers
      
      # Sets the path to the application file so it can be reloaded later.
      #
      def inherited(subclass)
        Pakyow::Configuration::App.application_path = parse_path_from_caller(caller[0])
      end
      
      def parse_path_from_caller(caller)
        caller.match(/^(.+)(:?:\d+(:?:in `.+')?$)/)[1]
      end
      
      # Runs the application. Accepts the environment(s) to run, for example:
      # run(:development)
      # run([:development, :staging])
      #
      def run(*args)
        return if running?
        @running = true
        
        self.builder.run(self.prepare(*args))
        detect_handler.run(builder, :Host => Pakyow::Configuration::Base.server.host, :Port => Pakyow::Configuration::Base.server.port)
      end
      
      # Stages the application. Everything is loaded but the application is
      # not started. Accepts the same arguments as #run.
      #
      def stage(*args)
        return if staged?
        @staged = true
        
        prepare(*args)
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
      
      # Creates routes. Example:
      # routes { get '/' { # do something } }
      #
      def routes(&block)
        self.routes_proc = block
      end
      
      # Creates an error handler (currently 404 and 500 errors are handled). 
      # The handler can be created one of two ways:
      #
      # Define a controller/action for a particular error:
      # error(404, :ApplicationController, :handle_404)
      #
      # Specify a block for a particular error:
      # error(404) { # handle error }
      #
      def error(*args, &block)
        self.error_handlers ||= {}
        code, controller, action = args
        
        if block
          self.error_handlers[code] = block
        else
          self.error_handlers[code] = {
            :controller => controller, 
            :action => action
          }
        end
      end
      
      def middleware(&block)
        self.middleware_proc = block
      end

      protected
      
      # Prepares the application for running or staging and returns an instance
      # of the application.
      def prepare(*args)
        self.load_config args.empty? || args.first.nil? ? [Configuration::Base.app.default_environment] : args
        return if prepared?
        
        self.builder.use(Rack::MethodOverride)
        self.builder.use(Pakyow::Static) if Configuration::Base.app.static
        self.builder.use(Pakyow::Logger) if Configuration::Base.app.log
        self.builder.use(Pakyow::Reloader) if Configuration::Base.app.auto_reload
        self.builder.instance_eval(&self.middleware_proc) if self.middleware_proc
        
        @prepared = true
        
        $:.unshift(Dir.pwd) unless $:.include? Dir.pwd
        return self.new
      end
      
      def load_config(args)
        if self.configurations
          args << Configuration::Base.app.default_environment if args.empty?
          args.each do |env|
            next unless config = self.configurations[env]
            Configuration::Base.instance_eval(&config)
          end
        end
      end
      
      def detect_handler
        ['thin', 'mongrel', 'webrick'].each do |server|
          begin
            return Rack::Handler.get(server)
          rescue LoadError
          rescue NameError
          end
        end
      end
    end

    include Helpers
    
    attr_accessor :request, :response, :presenter, :route_store, :restful_routes
    
    def initialize
      Pakyow.app = self
      
      # This configuration option will be set if a presenter is to be used
      if Configuration::Base.app.presenter
        # Create a new instance of the presenter
        self.presenter = Configuration::Base.app.presenter.new
      end
      
      # Load application files
      load_app
    end
    
    # Interrupts the application and returns response immediately.
    #
    def halt!
      @halted = true
      throw :halt, self.response
    end

    def halted?
      @halted
    end

    # Called on every request.
    #
    def call(env)
      @halted = false
      self.request = Request.new(env)
      self.response = Rack::Response.new

      working_request_path = self.request.path
      while working_request_path do
        controller_block = nil
        working_request_path = catch(:halt) {
          if Configuration::Base.app.presenter
            self.presenter.prepare_for_request(request)
          end

          working_route, working_format = StringUtils.split_at_last_dot(working_request_path)
          self.request.format = ((working_format && (working_format[working_format.length - 1, 1] == '/')) ? working_format[0, working_format.length - 1] : working_format)

          controller_block, packet = @route_store.get_block(working_route, self.request.method)

          request.params.merge!(HashUtils.strhash(packet[:vars]))
          self.request.route_spec = packet[:data][:route_spec] if packet[:data]
          restful_info = packet[:data][:restful] if packet[:data]
          self.request.restful = restful_info

          working_request_path = nil
          controller_block.call() if controller_block && !Pakyow::Configuration::App.ignore_routes
        }

        if !halted? && working_request_path
          next
        end

        if !halted? then
          if Configuration::Base.app.presenter
            self.response.body = [self.presenter.content]
          end
          # 404 if no facts matched and no views were found
          if !controller_block && (!self.presenter || !self.presenter.presented?)
            self.handle_error(404)
            Log.enter "[404] Not Found"
            self.response.status = 404
          end
        end
        
      end

      finish!

    rescue StandardError => error
      self.request.error = error
      self.handle_error(500)
      
      if Configuration::Base.app.errors_in_browser
        self.response.body = []
        self.response.body << "<h4>#{CGI.escapeHTML(error.to_s)}</h4>"
        self.response.body << error.backtrace.join("<br />")
      end
      
      self.response.status = 500
      
      begin
        # caught by other middleware (e.g. logger)
        throw :error, error
      rescue ArgumentError
      end
      
      finish!
    end

    def invoke_route(route)
      throw :halt, route
    end

    # Sends a file in the response (immediately). Accepts a File object. Mime 
    # type is automatically detected.
    #
    def send_file(source_file, send_as = nil, type = nil)
      path = source_file.is_a?(File) ? source_file.path : source_file
      send_as ||= path
      type    ||= Rack::Mime.mime_type(".#{send_as.split('.')[-1]}")
      
      data = ""
      File.open(path, "r").each_line { |line| data << line }
      
      self.response = Rack::Response.new(data, self.response.status, self.response.header.merge({ "Content-Type" => type }))
      halt!
    end
    
    # Sends data in the response (immediately). Accepts the data, mime type, 
    # and optional file name.
    #
    def send_data(data, type, file_name = nil)
      status = self.response ? self.response.status : 200
      
      headers = self.response ? self.response.header : {}
      headers = headers.merge({ "Content-Type" => type })
      headers = headers.merge({ "Content-disposition" => "attachment; filename=#{file_name}"}) if file_name
      
      self.response = Rack::Response.new(data, status, headers)
      halt!
    end
    
    # Redirects to location (immediately).
    #
    def redirect_to(location, status_code = 302)
      headers = self.response ? self.response.header : {}
      headers = headers.merge({'Location' => location})
      
      self.response = Rack::Response.new('', status_code, headers)
      halt!
    end
    
    # Registers a route for GET requests. Route can be defined one of two ways:
    # get('/', :ControllerClass, :action_method)
    # get('/') { # do something }
    #
    # Routes for namespaced controllers (e.g. Admin::ControllerClass) can be defined like this:
    # get('/', :Admin_ControllerClass, :action_method)
    #
    def get(route, *args, &block)
      register_route(:user, route, block, :get, *args)
    end
    
    # Registers a route for POST requests (see #get).
    #
    def post(route, *args, &block)
      register_route(:user, route, block, :post, *args)
    end
    
    # Registers a route for PUT requests (see #get).
    #
    def put(route, *args, &block)
      register_route(:user, route, block, :put, *args)
    end
    
    # Registers a route for DELETE requests (see #get).
    #
    def delete(route, *args, &block)
      register_route(:user, route, block, :delete, *args)
    end
    
    # Registers the default route (see #get).
    #
    def default(*args, &block)
      register_route(:user, '/', block, :get, *args)
    end

    # Creates REST routes for a resource. Arguments: url, controller, model, hooks
    #
    def restful(url, controller, *args, &block)
      model, hooks = parse_restful_args(args)
      
      with_scope(:url => url.gsub(/^[\/]+|[\/]+$/,""), :model => model) do
        nest_scope(&block) if block_given?
        
        @restful_routes         ||= {}
        @restful_routes[model]  ||= {} if model
        
        @@restful_actions.each do |opts|
          action_url = current_path          
          if suffix = opts[:url_suffix]
            action_url = File.join(action_url, suffix)
          end
          
          # Create the route
          register_route(:restful, action_url, nil, opts[:method], controller, opts[:action], hooks)
          
          # Store url for later use (currently used by Binder#action)
          @restful_routes[model][opts[:action]] = action_url if model
        end
        
        remove_scope
      end
    end
    
    @@restful_actions = [
      { :action => :edit, :method => :get, :url_suffix => 'edit/:id' },
      { :action => :show, :method => :get, :url_suffix => ':id' },
      { :action => :new, :method => :get, :url_suffix => 'new' },
      { :action => :update, :method => :put, :url_suffix => ':id' },
      { :action => :delete, :method => :delete, :url_suffix => ':id' },
      { :action => :index, :method => :get },
      { :action => :create, :method => :post }
    ]

    def hook(name, controller = nil, action = nil, &block)
      block = build_controller_block(controller, action) if controller
      @route_store.add_hook(name, block)
    end
    
    #TODO: don't like this...
    def reload
      load_app
    end
    
    protected
    
    def parse_route_args(args)
      controller = args[0] if args[0] && (args[0].is_a?(Symbol) || args[0].is_a?(String))
      action = args[1] if controller
      hooks = args[2] if controller
      unless controller
        hooks = args[0] if args[0] && args[0].is_a?(Hash)
      end
      return controller, action, hooks
    end

    def parse_restful_args(args)
      model = args[0] if args[0] && (args[0].is_a?(Symbol) || args[0].is_a?(String))
      hooks = args[1] if model
      unless model
        hooks = args[0] if args[0] && args[0].is_a?(Hash)
      end
      return model, hooks
    end

    # Handles route registration.
    #
    def register_route(type, route, block, method, *args)
      controller, action, hooks = parse_route_args(args)
      if controller
        block = build_controller_block(controller, action)
      end

      data = {:route_type=>type, :route_spec=>route}
      if type == :restful
        data[:restful] = {:restful_action=>action}
      end
      @route_store.add_route(route, block, method, data, hooks)
    end

    def build_controller_block(controller, action)
      controller = eval(controller.to_s)
      action ||= Configuration::Base.app.default_action

      block = lambda {
        instance = controller.new
        request.controller  = instance
        request.action      = action

        instance.send(action)
      }
      
      block
    end
    
    def with_scope(opts)
      @scope         ||= {}
      @scope[:path]  ||= []
      @scope[:model] = opts[:model]
      
      @scope[:path] << opts[:url]
      
      yield
    end
    
    def remove_scope
      @scope[:path].pop
    end
    
    def nest_scope(&block)
      @scope[:path].insert(-1, ":#{StringUtils.underscore(@scope[:model].to_s)}_id")
      yield
      @scope[:path].pop
    end
    
    def current_path
      @scope[:path].join('/')
    end
    
    def handle_error(code)
      return unless self.class.error_handlers
      return unless handler = self.class.error_handlers[code]
      
      if handler.is_a? Proc
        Pakyow.app.instance_eval(&handler)
      else
        c = eval(handler[:controller].to_s).new
        c.send(handler[:action])
      end
      
      self.response.body = [self.presenter.content] if Configuration::Base.app.presenter
    end
    
    def set_cookies
      if self.request.cookies && self.request.cookies != {}
        self.request.cookies.each do |key, value|
          if value.is_a?(Hash)
            self.response.set_cookie(key, {:path => '/', :expires => Time.now + 604800}.merge(value))
          elsif value.is_a?(String)
            self.response.set_cookie(key, {:path => '/', :expires => Time.now + 604800}.merge({:value => value}))
          else
            self.response.set_cookie(key, {:path => '/', :expires => Time.now + 604800 * -1 }.merge({:value => value}))
          end
        end
      end
    end
    
    # Reloads all application files in application_path and presenter (if specified).
    #
    def load_app
      load(Configuration::App.application_path)
      
      @loader = Loader.new unless @loader
      @loader.load!(Configuration::Base.app.src_dir)
      
      load_routes
      
      # Reload views
      if Configuration::Base.app.presenter
        self.presenter.load
      end
    end
    
    def load_routes
      @route_store = RouteStore.new
      self.instance_eval(&self.class.routes_proc) if self.class.routes_proc
    end
    
    # Send the response and cleanup.
    #
    def finish!
      set_cookies
      self.response.finish
    end

  end
end
