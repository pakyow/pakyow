module Pakyow
  class Request
    # Returns true if the request occurred over a WebSocket.
    # 
    # @api public
    def socket?
      env['pakyow.socket'] == true
    end
  end
end
