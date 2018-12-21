# frozen_string_literal: true

module Pakyow
  # Makes an object bindable.
  #
  module Bindable
    def include?(key)
      respond_to?(key.to_s.to_sym)
    end

    def [](key)
      if include?(key)
        public_send(key.to_s.to_sym)
      end
    end
  end
end
