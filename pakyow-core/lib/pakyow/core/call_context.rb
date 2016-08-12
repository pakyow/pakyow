require 'pakyow/core/helpers'
require 'pakyow/core/helpers/hooks'
require 'pakyow/core/router'
require 'pakyow/core/request'
require 'pakyow/core/response'
require 'pakyow/core/app_context'

module Pakyow
  class CallContext
    include Helpers
    include Helpers::Hooks::InstanceMethods


    def initialize(env)
      @router = Pakyow::Router.instance

      req = Request.new(env)
      res = Response.new

      # set response format based on request
      res.format = req.format

      @context = AppContext.new(req, res)
    end

    def process
      hook_around :process do
        set_initial_cookies

        @found = false
        catch :halt do
          hook_around :route do
            @found = @router.perform(context, self) {
              call_hooks :after, :match
            }
          end

          handle(404, false) unless found?
        end

        set_cookies
      end

      self
    rescue StandardError => error
      request.error = error

      catch :halt do
        hook_around :error do
          handle(500, false) unless found?
        end
      end

      self
    end

    # Interrupts the application and returns response immediately.
    #
    def halt
      throw :halt, response
    end

    # Routes the request to different logic.
    #
    def reroute(location, method = nil)
      location = @router.path(location)
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
      if file_or_data.is_a?(IO) || file_or_data.is_a?(StringIO)
        data = file_or_data

        if file_or_data.is_a?(File)
          # auto set type based on file type
          type ||= Rack::Mime.mime_type("." + String.split_at_last_dot(file_or_data.path)[1])
        end
      elsif file_or_data.is_a?(String)
        data = StringIO.new(file_or_data)
      else
        raise ArgumentError, 'Expected an IO or String object'
      end

      headers = {}
      headers["Content-Type"]         = type if type
      headers["Content-disposition"]  = "attachment; filename=#{send_as}" if send_as

      res.body = data
      res.header.merge!(headers)

      halt
    end

    # Redirects to location (immediately).
    #
    def redirect(location, status_code = 302)
      location = @router.path(location)

      headers = response ? response.header : {}
      headers = headers.merge({'Location' => location})

      self.context.response = Response.new('', status_code, headers)
      halt
    end

    def handle(name_or_code, from_logic = true)
      @handling = true

      hook_around :route do
        @router.handle(name_or_code, self, from_logic)
      end
    end

    def finish
      res.finish
    end

    protected

    def found?
      @found
    end

    def handling?
      @handling
    end

    def call_hooks(type, trigger)
      Pakyow::App.hook(type, trigger).each do |block|
        instance_exec(&block)
      end
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
  end
end
