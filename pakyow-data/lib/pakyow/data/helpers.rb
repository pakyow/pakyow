module Pakyow
  module Helpers
    def verify(&block)
      request.verify(&block)
    end

    def data
      Pakyow.data_model_lookup
    end
  end
end
