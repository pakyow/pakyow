module Pakyow
  class Request
    old_params = instance_method(:params)

    define_method :params do
      env.fetch('pakyow.params', old_params.bind(self).())
    end
  end
end
