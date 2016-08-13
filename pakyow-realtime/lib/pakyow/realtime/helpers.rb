module Pakyow
  class App
    # @api private
    def socket
      Realtime::Context.new(self)
    end
  end
end

module Pakyow
  module Helpers
    # Returns a working realtime context for the current app context.
    #
    # @api public
    def socket
      Realtime::Context.new(self)
    end

    # @api private
    def socket_key
      return params[:socket_key] if params[:socket_key]
      session[:socket_key] ||= Realtime::Connection.socket_key
    end

    # @api private
    def socket_connection_id
      return params[:socket_connection_id] if params[:socket_connection_id]
      @socket_connection_id ||= Realtime::Connection.socket_connection_id
    end

    # @api private
    def socket_digest(socket_connection_id)
      Realtime::Connection.socket_digest(socket_key, socket_connection_id)
    end
  end
end
