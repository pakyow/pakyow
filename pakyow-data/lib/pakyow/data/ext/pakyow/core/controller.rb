# frozen_string_literal: true

require "pakyow/data/verification"

module Pakyow
  class Controller
    include Data::Verification
    verifies :params

    def data
      app.data_model_lookup
    end
  end
end
