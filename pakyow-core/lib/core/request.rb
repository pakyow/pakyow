module Pakyow

  # The Request object.
  class Request < Rack::Request
    attr_accessor :restful, :route_path, :controller, :action, :format, :error, :working_path, :working_method, :initial_cookies

    def initialize(*args)
      super

      @initial_cookies = []
      self.cookies.each {|k|
        @initial_cookies
      }
    end

    # Easy access to path_info.
    def path
      self.path_info
    end
    
    # Determines the request method.
    def method
      request_method.downcase.to_sym
    end

    def format=(format)
      @format = format ? format.to_sym : :html
      
      # Set response type
      Pakyow.app.response["Content-Type"] = Rack::Mime.mime_type(".#{@format}")
    end

    def session
      self.env['rack.session'] || {}
    end
    
    def cookies
      @cookies ||= HashUtils.strhash(super)
    end
    
    # Returns indifferent params (see {HashUtils.strhash} for more info on indifferent hashes).
    def params
      @params ||= HashUtils.strhash(super)
    end
    
    # Returns array of url components.
    def path_parts
      @url ||= self.path ? self.class.split_url(self.path) : []
    end

    def referer
      @referer ||= self.env['HTTP_REFERER']
    end
    
    # Returns array of referer components.
    def referer_parts
      @referer_parts ||= self.referer ? self.class.split_url(self.referer) : []
    end

    def setup(path = self.path, method = nil)
      self.set_request_format_from_path(path)
      self.set_working_path_from_path(path, method)
    end

    #TODO move to util class
    def self.split_url(url)
      arr = []
      url.split('/').each { |r|
        arr << r unless r.empty?
      }
      
      return arr
    end

    protected

    def set_working_path_from_path(path, method)
      base_route, ignore_format = StringUtils.split_at_last_dot(path)

      self.working_path = base_route
      self.working_method = method || self.method
    end

    def set_request_format_from_path(path)
      path, format = StringUtils.split_at_last_dot(path)
      self.format = ((format && (format[format.length - 1, 1] == '/')) ? format[0, format.length - 1] : format)
    end
  end
end
