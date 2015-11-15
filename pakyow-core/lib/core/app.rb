module Pakyow
  class App
    class << self
      attr_reader :path

      # Prepares the app for being staged in one or more environments by
      # loading config(s), middleware, and setting the load path.
      #
      def prepare(*env_or_envs)
        return if prepared?

        # load config for one or more environments
        load_config(*env_or_envs)

        # load each block from middleware stack
        load_middleware

        # include pwd in load path
        $:.unshift(Dir.pwd) unless $:.include? Dir.pwd

        @prepared = true
      end

      # Stages the app by preparing and returning an instance. This is
      # essentially everything short of running it.
      #
      def stage(*env_or_envs)
        unless staged?
          prepare(*env_or_envs)
          @staged = true
        end

        self.new
      end

      # Runs the staged app.
      #
      def run(*env_or_envs)
        return if running?

        @running = true

        builder.run(stage(*env_or_envs))
        detect_handler.run(builder, Host: config.server.host, Port: config.server.port) do |server|
          trap(:INT)  { stop(server) }
          trap(:TERM) { stop(server) }
        end
      end

      # Defines an app
      #
      def define(&block)
        # sets the path to the app file so it can be reloaded later
        @path = String.parse_path_from_caller(caller[0])
        self.instance_eval(&block)
      end

      # Defines a route set.
      #
      def routes(set_name = :main, &block)
        if set_name && block
          @@routes[set_name] = block
        else
          @@routes
        end
      end

      # Accepts block to be added to middleware stack.
      #
      def middleware(&block)
        @@middleware << block
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
        Pakyow::Config
      end

      def reset
        @prepared = false
        @staged = false
        @running = false

        @@routes = {}
        @@config = {}
        @@middleware = []

        @@stacks = {:before => {}, :after => {}}
        %w(init load process route match error).each {|name|
          @@stacks[:before][name.to_sym] = []
          @@stacks[:after][name.to_sym] = []
        }
      end

      def load_config(*env_or_envs)
        envs = Array.ensure(env_or_envs)
        envs = envs.empty? || envs.first.nil? ? [config.app.default_environment] : envs

        config.app.loaded_envs = envs
        config.env = envs.first.to_sym

        # run specific config first
        envs.each do |env|
          next unless config_proc = @@config[env.to_sym]
          config.app_config(&config_proc)
        end

        # then run global config
        if global_proc = @@config[:global]
          config.app_config(&global_proc)
        end
      end

      protected

      def load_middleware
        @@middleware.each do |mw|
          self.instance_exec(builder, &mw)
        end

        builder.use(Rack::MethodOverride)
        builder.use(Middleware::Static)   if config.app.static
        builder.use(Middleware::Logger)   if config.app.log
        builder.use(Middleware::Reloader) if config.app.auto_reload
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

    attr_writer :context

    def initialize
      Pakyow.app = self
      Pakyow.configure_logger

      call_stack(:before, :init)

      load_app

      call_stack(:after, :init)
    end

    # Returns the primary (first) loaded env.
    #
    def env
      config.env
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

      req = Request.new(env)
      res = Response.new

      # set response format based on request
      res.format = req.format

      @context = AppContext.new(req, res)

      set_initial_cookies

      @found = false
      catch(:halt) {
        call_stack(:before, :route)

        @found = @router.perform(context, self) {
          call_stack(:after, :match)
        }

        call_stack(:after, :route)

        unless found?
          handle(404, false)

          present_error 404 do |content|
            path = String.normalize_path(request.path)
            path = '/' if path.empty?

            content.gsub!('{route_path}', path)
            content
          end
        end
      }

      set_cookies

      call_stack(:after, :process)

      response.finish
    rescue StandardError => error
      request.error = error

      catch :halt do
        call_stack(:before, :error)

        handle(500, false) unless found?

        present_error 500 do |content|
          nice_source = error.backtrace[0].match(/^(.+?):(\d+)(|:in `(.+)')$/)

          content.gsub!('{file}', nice_source[1].gsub(File.expand_path(Config.app.root) + '/', ''))
          content.gsub!('{line}', nice_source[2])

          content.gsub!('{msg}', CGI.escapeHTML("#{error.class}: #{error}"))
          content.gsub!('{trace}', error.backtrace.map { |bt| CGI.escapeHTML(bt) }.join('<br>'))

          content
        end
      end

      call_stack(:after, :error)

      response.finish
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
      config.reset

      # reload config
      self.class.load_config(*envs)

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
    def reroute(location, method = nil)
      location = Router.instance.path(location)
      request.setup(location, method)

      call_stack(:before, :route)
      call_stack(:after, :match)
      @router.reroute(request)
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
        type ||= Rack::Mime.mime_type("." + String.split_at_last_dot(file_or_data.path)[1])
      else
        data = file_or_data
      end

      headers = {}
      headers["Content-Type"]         = type if type
      headers["Content-disposition"]  = "attachment; filename=#{send_as}" if send_as

      self.context.response = Response.new(data, response.status, response.header.merge(headers))
      halt
    end

    # Redirects to location (immediately).
    #
    def redirect(location, status_code = 302)
      location = Router.instance.path(location)

      headers = response ? response.header : {}
      headers = headers.merge({'Location' => location})

      self.context.response = Response.new('', status_code, headers)
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
      @loader ||= Loader.new
      @loader.load_from_path(config.app.src_dir)

      # load the routes
      load_routes

      call_stack(:after, :load)
    end

    def load_routes
      @router = Router.instance.reset
      self.class.routes.each_pair {|set_name, block|
        @router.set(set_name, &block)
      } unless config.app.ignore_routes
    end

    def set_cookies
      request.cookies.each_pair {|k, v|
        response.delete_cookie(k) if v.nil?

        # cookie is already set with value, ignore
        next if @initial_cookies.include?(k.to_s) && @initial_cookies[k.to_s] == v

        # set cookie with defaults
        response.set_cookie(k, {
          :path => config.cookies.path,
          :expires => config.cookies.expiration,
          :value => v
        })
      }

      # delete cookies that are no longer present
      @initial_cookies.each {|k|
        response.delete_cookie(k) unless request.cookies.key?(k.to_s)
      }
    end

    # Stores set cookies at beginning of request cycle
    # for comparison at the end of the cycle
    def set_initial_cookies
      @initial_cookies = {}
      request.cookies.each {|k,v|
        @initial_cookies[k] = v
      }
    end

    def present_error(code)
      return unless config.app.errors_in_browser

      response["Content-Type"] = 'text/html'

      if block_given?
        content = yield(content_for_code(code))
      end

      response.body = [content]
    end

    def content_for_code(code)
      File.open(
        File.join(
          'views',
          'errors',
          code.to_s + '.html'
        )
      ).read
    end

  end

  App.reset
end
