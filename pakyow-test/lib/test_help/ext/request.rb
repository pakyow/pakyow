module Pakyow
  class Request
    def params
      env['pakyow.params']
    end
  end
end
