module Pakyow
  class App
    class << self
      def reset
        @@routes = {}
        @@config = {}

        @@stacks = {:before => {}, :after => {}}
        %w(init load process route match error).each {|name|
          @@stacks[:before][name.to_sym] = []
          @@stacks[:after][name.to_sym] = []
        }
      end

      # Defines an app
      #
      def define(&block)
        # sets the path to the app file so it can be reloaded later
        config.app.path = StringUtils.parse_path_from_caller(caller[0])

        self.instance_eval(&block)
      end

      # Defines a route set.
      #
      #TODO default route set should be config option (also for bindings)
      def routes(set_name = :main, &block)
        if set_name && block
          @@routes[set_name] = block
        else
          @@routes
        end
      end

      # Defines middleware to be loaded.
      #
      def middleware(&block)
        # prevents middleware from being loaded on each
        # request when auto_reload is enabled
        return if prepared?

        # tell builder about the middleware
        builder.instance_eval(&block)
      end

      # Creates an environment.
      #
      def configure(env, &block)
        @@config[env] = block
      end

      # Fetches a stack (before | after) by name.
      #
      def stack(which, name)
        @@stacks[which][name]
      end

      # Adds a block to the before stack for `stack_name`.
      #
      def before(stack_name, &block)
        @@stacks[:before][stack_name.to_sym] << block
      end

      # Adds a block to the after stack for `stack_name`.
      #
      def after(stack_name, &block)
        @@stacks[:after][stack_name.to_sym] << block
      end

      # Runs the application. Accepts the environment(s) to run, for example:
      # run(:development)
      # run([:development, :staging])
      #
      def run(*args)
        return if running?

        @running = true
        builder.run(prepare(args))
        detect_handler.run(builder, :Host => config.server.host, :Port => config.server.port) do |server|
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
        Pakyow::Config::Base
      end

      def load_config(envs)
        # run global config first
        if global_proc = @@config[:global]
          config.instance_eval(&global_proc)
        end

        # then run other envs

        envs.each do |env|
          next unless config_proc = @@config[env.to_sym]
          config.instance_eval(&config_proc)
        end

        config.app.loaded_envs = envs
      end

      protected

      # Prepares the application for running or staging and returns an instance
      # of the application.
      def prepare(envs)
        return if prepared?

        # configure
        envs = envs.empty? || envs.first.nil? ? [config.app.default_environment] : envs
        load_config(envs)

        # load middleware
        builder.use(Rack::MethodOverride)
        builder.use(Middleware::Static)   if config.app.static
        builder.use(Middleware::Logger)   if config.app.log
        builder.use(Middleware::Reloader) if config.app.auto_reload

        # prepare for logging
        Log.reopen

        @prepared = true

        $:.unshift(Dir.pwd) unless $:.include? Dir.pwd

        return self.new
      end

      def detect_handler
        handlers = ['puma', 'thin', 'mongrel', 'webrick']
        handlers.unshift(config.server.handler) if config.server.handler

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
    include AppHelpers

    attr_accessor :request, :response

    def initialize
      Pakyow.app = self

      call_stack(:before, :init)

      load_app

      call_stack(:after, :init)
    end

    # Returns the primary (first) loaded env.
    #
    def env
      config.app.loaded_envs[0]
    end

    def app
      self
    end

    def call(env)
      dup.process(env)
    end

    # Called on every request.
    #
    def process(env)
      call_stack(:before, :process)

      @response = Response.new
      @request  = Request.new(env)
      @request.app = self
      @request.setup

      set_initial_cookies

      @found = false
      catch(:halt) {
        unless config.app.ignore_routes
          call_stack(:before, :route)

          @found = @router.perform(@request, self) {
            call_stack(:after, :match)
          }

          call_stack(:after, :route)
        end

        handle(404, false) unless found?
      }

      set_cookies

      call_stack(:after, :process)

      @response.finish
    rescue StandardError => error
      call_stack(:before, :error)

      @request.error = error

      handle(500, false) unless found?

      if config.app.errors_in_browser
        @response["Content-Type"] = 'text/html'
        @response.body = []
        @response.body << "<h4>#{CGI.escapeHTML(error.to_s)}</h4>"
        @response.body << error.backtrace.join("<br />")
      end

      call_stack(:after, :error)

      @response.finish
    end

    def found?
      @found
    end

    # This is NOT a useless method, it's a part of the external api
    def reload
      # reload the app file
      load(config.app.path)

      # reset config
      envs = config.app.loaded_envs
      config.reset!

      # reload config
      self.class.load_config(envs)

      load_app
    end

    # APP ACTIONS

    # Interrupts the application and returns response immediately.
    #
    def halt
      throw :halt, @response
    end

    # Routes the request to different logic.
    #
    def reroute(path, method = nil)
      @request.setup(path, method)

      call_stack(:before, :route)
      @router.reroute(@request)
      call_stack(:after, :route)
    end

    # Sends data in the response (immediately). Accepts a string of data or a File,
    # mime-type (auto-detected; defaults to octet-stream), and optional file name.
    #
    # If a File, mime type will be guessed. Otherwise mime type and file name will
    # default to whatever is set in the response.
    #
    def send(file_or_data, type = nil, send_as = nil)
      if file_or_data.class == File
        data = file_or_data.read

        # auto set type based on file type
        type = Rack::Mime.mime_type("." + StringUtils.split_at_last_dot(file_or_data.path)[1])
      else
        data = file_or_data
      end

      headers = {}
      headers["Content-Type"]         = type if type
      headers["Content-disposition"]  = "attachment; filename=#{send_as}" if send_as

      @response = Response.new(data, @response.status, @response.header.merge(headers))
      halt
    end

    # Redirects to location (immediately).
    #
    def redirect(location, status_code = 302)
      headers = response ? response.header : {}
      headers = headers.merge({'Location' => location})

      app.response = Response.new('', status_code, headers)
      halt
    end

    def handle(name_or_code, from_logic = true)
      call_stack(:before, :route)
      @router.handle(name_or_code, self, from_logic)
      call_stack(:after, :route)
    end

    # Convenience method for defining routes on an app instance.
    #
    def routes(set_name = :main, &block)
      self.class.routes(set_name, &block)
      load_routes
    end

    protected

    def call_stack(which, stack)
      self.class.stack(which, stack).each {|block|
        self.instance_exec(&block)
      }
    end

    # Reloads all application files in path and presenter (if specified).
    #
    def load_app
      call_stack(:before, :load)

      # load src files
      @loader = Loader.new
      @loader.load_from_path(config.app.src_dir)

      # load the routes
      load_routes

      call_stack(:after, :load)
    end

    def load_routes
      @router = Router.instance.reset
      self.class.routes.each_pair {|set_name, block|
        @router.set(set_name, &block)
      }
    end

    def set_cookies
      @request.cookies.each_pair {|k, v|
        @response.unset_cookie(k) if v.nil?

        # cookie is already set with value, ignore
        next if @initial_cookies.include?(k.to_s) && @initial_cookies[k.to_s] == v

        # set cookie with defaults
        @response.set_cookie(k, {
          :path => config.cookies.path,
          :expires => config.cookies.expiration,
          :value => v
        })
      }

      # delete cookies that are no longer present
      @initial_cookies.each {|k|
        @response.delete_cookie(k) unless @request.cookies.key?(k.to_s)
      }
    end

    # Stores set cookies at beginning of request cycle
    # for comparison at the end of the cycle
    def set_initial_cookies
      @initial_cookies = {}
      @request.cookies.each {|k,v|
        @initial_cookies[k] = v
      }
    end

  end

  App.reset
end
