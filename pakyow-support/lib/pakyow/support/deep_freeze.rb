module Pakyow
  module Support
    module DeepFreeze
      UNFREEZABLE = %w(Rack::Builder).freeze

      refine Object do
        def deep_freeze
          return self if unfreezable?

          self.freeze

          instance_variables.each do |name|
            instance_variable_get(name).deep_freeze
          end

          self
        end

        private

        def unfreezable?
          frozen? || UNFREEZABLE.include?(self.class.name)
        end
      end

      refine Array do
        def deep_freeze
          return self if unfreezable?

          self.freeze

          each(&:deep_freeze)

          self
        end
      end
    end
  end
end

