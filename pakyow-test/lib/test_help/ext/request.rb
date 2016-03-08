module Pakyow
  module ParamsOverride
    def params
      env.fetch('pakyow.params') { super }
    end
  end

  class Request
    prepend ParamsOverride
  end
end
