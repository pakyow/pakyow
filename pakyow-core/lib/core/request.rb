module Pakyow

  # The Request object.
  class Request < Rack::Request
    attr_accessor :restful, :route_spec, :controller, :action, :format, :error, :working_path, :working_method

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
    
    def cookies
      @cookies ||= HashUtils.strhash(super)
    end
    
    # Returns indifferent params (see {HashUtils.strhash} for more info on indifferent hashes).
    def params
      @params ||= HashUtils.strhash(super)
    end
    
    # Returns array of url components.
    def url_parts
      unless @url
        @url = self.class.split_url(self.env['PATH_INFO'])
      end
    
      return @url
    end
    
    # Returns array of referer components.
    def referer_parts
      unless @referer
        @referer = self.class.split_url(self.env['HTTP_REFERER'])
      end
    
      return @referer
    end
    
    private
    
    def self.split_url(url)
      arr = []
      url.split('/').each { |r|
        arr << r unless r.empty?
      }
      
      return arr
    end
  end
end
