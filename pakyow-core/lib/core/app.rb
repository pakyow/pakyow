require_relative 'helpers/configuring'
require_relative 'helpers/running'
require_relative 'helpers/hooks'

module Pakyow
  # The main app object.
  #
  # @api public
  class App
    extend Helpers::Configuring
    extend Helpers::Running
    extend Helpers::Hooks

    class << self
      # Convenience method for accessing app configuration.
      #
      # @api public
      def config
        Pakyow::Config
      end

      # Resets all the app state.
      #
      # @api private
      def reset
        instance_variables.each do |ivar|
          remove_instance_variable(ivar)
        end
      end
    end

    include Helpers
    include AppHelpers

    attr_writer :context

    def initialize
      Pakyow.app = self

      hook_around :init do
        load_app
      end
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
      hook_around :process do
        req = Request.new(env)
        res = Response.new

        # set response format based on request
        res.format = req.format

        @context = AppContext.new(req, res)

        set_initial_cookies

        @found = false
        catch(:halt) {
          hook_around :route do
            @found = @router.perform(context, self) {
              call_hooks :after, :match
            }
          end

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
      end

      response.finish
    rescue StandardError => error
      request.error = error

      hook_around :error do
        catch :halt do
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
      end

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

      call_hooks :before, :route
      call_hooks :after, :match
      @router.reroute(request)
      call_hooks :after, :route
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
      hook_around :route do
        @router.handle(name_or_code, self, from_logic)
      end
    end

    # Convenience method for defining routes on an app instance.
    #
    def routes(set_name = :main, &block)
      self.class.routes(set_name, &block)
      load_routes
    end

    # Convenience method for defining resources on an app instance.
    #
    def resource(set_name, path, &block)
      self.class.resource(set_name, path, &block)
    end

    protected

    def hook_around(trigger)
      call_hooks :before, trigger
      yield
      call_hooks :after, trigger
    end

    def call_hooks(type, trigger)
      self.class.hook(type, trigger).each do |block|
        instance_exec(&block)
      end
    end

    # Reloads all application files in path and presenter (if specified).
    #
    def load_app
      hook_around :load do
        # load src files
        @loader ||= Loader.new
        @loader.load_from_path(config.app.src_dir)

        # load the routes
        load_routes
      end
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
end
