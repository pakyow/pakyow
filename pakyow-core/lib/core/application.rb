module Pakyow
  class Application
    class << self
      attr_accessor :core_proc, :middleware_proc, :configurations

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
        self.builder.run(self.prepare(args))
        detect_handler.run(builder, :Host => Pakyow::Configuration::Base.server.host, :Port => Pakyow::Configuration::Base.server.port) do |server|
          trap(:INT) { stop(server) }
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

      protected

      # Prepares the application for running or staging and returns an instance
      # of the application.
      def prepare(args)
        self.load_config args.empty? || args.first.nil? ? [Configuration::Base.app.default_environment] : args
        return if prepared?

        self.builder.use(Rack::MethodOverride)
        self.builder.instance_eval(&self.middleware_proc) if self.middleware_proc
        self.builder.use(Pakyow::Static) if Configuration::Base.app.static
        self.builder.use(PresenterMiddleware) if Configuration::Base.app.presenter
        self.builder.use(Pakyow::Logger) if Configuration::Base.app.log
        self.builder.use(Pakyow::Reloader) if Configuration::Base.app.auto_reload
        
        @prepared = true

        $:.unshift(Dir.pwd) unless $:.include? Dir.pwd
        return self.new
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

    attr_accessor :request, :response, :presenter, :route_store, :restful_routes, :handler_store

    def initialize
      Pakyow.app = self
      @handler_name_to_code = {}
      @handler_code_to_name = {}

      # This configuration option will be set if a presenter is to be used
      if Configuration::Base.app.presenter
        # Create a new instance of the presenter
        self.presenter = Configuration::Base.app.presenter.new
      end

      # Load application files
      load_app(false)
    end

    # Interrupts the application and returns response immediately.
    #
    def halt!
      throw :halt, self.response
    end

    def invoke_route!(route, method=nil)
      base_route, ignore_format = StringUtils.split_at_last_dot(route)
      self.request.working_path = base_route
      self.request.working_method = method if method
      block = prepare_route_block(route, self.request.working_method)
      throw :new_block, block
    end

    def invoke_handler!(name_or_code)
      if block = @handler_store[name_or_code]
        # we are given a name
        code = @handler_name_to_code[name_or_code]
        self.response.status = code if code
        throw :new_block, block
      elsif name = @handler_code_to_name[name_or_code]
        # we are given a code
        block = @handler_store[name]
        self.response.status = name_or_code
        throw :new_block, block
      else
        # no block to be found
        # do we assume code if a number and set status?
        self.response.status = name_or_code if name_or_code.is_a?(Fixnum)
        # still need to stop execution, I think? But do nothing.
        throw :new_block, nil
      end
    end

    # Called on every request.
    #
    def call(env)
      self.request = Request.new(env)
      self.response = Rack::Response.new
      base_route, ignore_format = StringUtils.split_at_last_dot(self.request.path)
      self.request.working_path = base_route
      self.request.working_method = self.request.method

      has_route = false
      catch(:halt) {
        route_block = prepare_route_block(self.request.path, self.request.method)
        has_route = true if route_block
        has_route = trampoline(route_block)

        # 404 if no route matched and no views were found
        if !has_route && (!self.presenter || !self.presenter.presented?)
          Log.enter "[404] Not Found"
          handler404 = @handler_store[@handler_code_to_name[404]] if @handler_code_to_name[404]
          if handler404
            catch(:halt) {
              trampoline(handler404)
            }
          end
          self.response.status = 404
        end
      } #end :halt catch block

      # This needs to be in the 'return' position (last statement)
      finish!

    rescue StandardError => error
      self.request.error = error
      handler500 = @handler_store[@handler_code_to_name[500]] if @handler_code_to_name[500]
        if handler500
          catch(:halt) {
            if self.presenter
              self.presenter.prepare_for_request(self.request)
            end
            trampoline(handler500)
            if self.presenter then
              self.response.body = [self.presenter.content]
            end
          } #end :halt catch block
        end
      self.response.status = 500

      if Configuration::Base.app.errors_in_browser
        self.response.body = []
        self.response.body << "<h4>#{CGI.escapeHTML(error.to_s)}</h4>"
        self.response.body << error.backtrace.join("<br />")
      end

      begin
        # caught by other middleware (e.g. logger)
        throw :error, error
      rescue ArgumentError
      end

      finish!
    end

    # Sends a file in the response (immediately). Accepts a File object. Mime
    # type is automatically detected.
    #
    def send_file!(source_file, send_as = nil, type = nil)
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
    def send_data!(data, type, file_name = nil)
      status = self.response ? self.response.status : 200

      headers = self.response ? self.response.header : {}
      headers = headers.merge({ "Content-Type" => type })
      headers = headers.merge({ "Content-disposition" => "attachment; filename=#{file_name}"}) if file_name

      self.response = Rack::Response.new(data, status, headers)
      halt!
    end

    # Redirects to location (immediately).
    #
    def redirect_to!(location, status_code = 302)
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

    def handler(name, *args, &block)
      code, controller, action = parse_handler_args(args)

      if block_given?
        @handler_store[name] = block
      else
        @handler_store[name] = build_controller_block(controller, action)
      end

      if code
        @handler_name_to_code[name] = code
        @handler_code_to_name[code] = name
      end
    end

    def session
      self.request.env['rack.session'] || {}
    end

    protected

    def prepare_route_block(route, method)
      set_request_format_from_route(route)
      base_route, ignore_format = StringUtils.split_at_last_dot(route)
      
      if Pakyow::Configuration::App.ignore_routes
        controller_block, packet = nil, {:vars=>{}, :data=>nil}
      else
        controller_block, packet = @route_store.get_block(base_route, method)
      end

      self.request.params.merge!(HashUtils.strhash(packet[:vars]))
      self.request.route_spec = packet[:data][:route_spec] if packet[:data]
      self.request.restful = packet[:data][:restful] if packet[:data]

      controller_block
    end

    def trampoline(block)
      last_call_has_block = (block == nil) ? false : true
      while block do
        block = catch(:new_block) {
          block.call()
          # Getting here means that call() returned normally (not via a throw)
          :fall_through
        } # end :invoke_route catch block
        # If invoke_route! or invoke_handler! was called in the block, block will have a new value (nil or block).
        # If neither was called, block will be :fall_through

        if block == nil
          last_call_has_block = false
        elsif block == :fall_through
          last_call_has_block = true
          block = nil
        end

        if block && self.presenter
          self.presenter.prepare_for_request(self.request)
        end
      end
      last_call_has_block
    end

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

    def parse_handler_args(args)
      code = args[0] if args[0] && args[0].is_a?(Fixnum)
      controller = args[1] if code && args[1]
      action = args[2] if controller && args[2]
      unless code
        controller = args[0] if args[0]
        action = args[1] if controller && args[1]
      end
      return code, controller, action
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

    def set_request_format_from_route(route)
      route, format = StringUtils.split_at_last_dot(route)
      self.request.format = ((format && (format[format.length - 1, 1] == '/')) ? format[0, format.length - 1] : format)
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

      @loader = Loader.new unless @loader
      @loader.load!(Configuration::Base.app.src_dir)

      self.load_core

      # Reload presenter
      self.presenter.load if self.presenter
    end

    # Evaluates core_proc
    #
    def load_core
      @handler_store = {}
      @route_store = RouteStore.new

      self.instance_eval(&self.class.core_proc) if self.class.core_proc
    end
    
    # Send the response and cleanup.
    #
    def finish!
      set_cookies
      self.response.finish
    end

  end
end
