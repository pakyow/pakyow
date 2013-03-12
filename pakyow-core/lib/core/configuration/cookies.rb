module Pakyow
  module Configuration
    class Cookies
      class << self
        attr_accessor :path, :expiration
        
        # What path should the cookie be created for?
        def path
          @path || '/'
        end
        
        # When does the cookie expire?
        def expiration
          @expiration || Time.now + 60 * 60 * 24 * 7 # one week
        end
      end
    end
  end
end
