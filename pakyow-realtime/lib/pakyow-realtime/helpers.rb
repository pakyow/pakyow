module Pakyow
  module Helpers
    # Returns a working realtime context for the current app context.
    #
    # @api public
    def socket
      Realtime::Context.new(self)
    end

    # Returns the session's unique realtime key.
    #
    # @api private
    def socket_key
      return params[:socket_key] if params[:socket_key]
      session[:socket_key] ||= SecureRandom.hex(32)
    end

    # Returns the unique connection id for this request lifecycle.
    #
    # @api private
    def socket_connection_id
      @socket_connection_id ||= SecureRandom.hex(32)
    end

    # Returns a digest created from the connection id and socket_key.
    #
    # @api private
    def socket_digest(socket_connection_id)
      Digest::SHA1.hexdigest("--#{socket_key}--#{socket_connection_id}--")
    end
  end
end
