module Pakyow
  class App
    # @api private
    def socket
      Realtime::Context.new(self)
    end
  end
end
