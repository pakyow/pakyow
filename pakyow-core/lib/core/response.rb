module Pakyow

  # The Response object.
  class Response < Rack::Response
    def set_cookies
      Pakyow.app.request.cookies.each_pair {|k, v|
        self.unset_cookie(k) if v.nil?
        next if Pakyow.app.request.initial_cookies.include?(k.to_s) # cookie is already set, ignore

        # set cookie with defaults
        self.set_cookie(k, {
          :path => Configuration::Base.cookies.path, 
          :expires => Configuration::Base.cookies.expiration,
          :value => v
        })
      }

      # delete cookies that are no longer present
      Pakyow.app.request.initial_cookies.each {|k|
        self.unset_cookie(k) unless Pakyow.app.request.cookies.key?(k.to_s)
      }
    end

    def unset_cookie(key, data = {})
      self.set_cookie(key, {
        :path => data[:path] || Configuration::Base.cookies.path, 
        :expires => Time.now - 60 * 60 * 24
      })

      Pakyow.app.request.cookies.delete(key.to_s)
    end
  end
end
