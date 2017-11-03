module Pakyow
  class Controller
    # @api private
    def socket
      Realtime::Context.new(self)
    end

    # @api private
    def socket_key
      return request.params[:socket_key] if request.params[:socket_key]
      request.session[:socket_key] ||= Realtime::Connection.socket_key
    end

    # @api private
    def socket_connection_id
      return request.params[:socket_connection_id] if request.params[:socket_connection_id]
      @socket_connection_id ||= Realtime::Connection.socket_connection_id
    end

    # @api private
    def socket_digest(socket_connection_id)
      Realtime::Connection.socket_digest(socket_key, socket_connection_id)
    end
  end
end
