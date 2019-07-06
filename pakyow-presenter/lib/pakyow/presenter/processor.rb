# frozen_string_literal: true

require "pakyow/support/class_state"

module Pakyow
  module Presenter
    class Processor
      extend Support::ClassState
      class_state :name
      class_state :block
      class_state :extensions, default: [], getter: false

      extend Support::Makeable

      def initialize(app)
        @app = app
      end

      def call(content)
        self.class.process(content)
      end

      class << self
        # @api private
        def make(name, *extensions, **kwargs, &block)
          # Name is expected to also be an extension.
          #
          extensions.unshift(name).map!(&:to_sym)

          super(name, extensions: extensions, block: block, **kwargs) {}
        end

        def process(content)
          block.call(content)
        end

        def extensions(*extensions)
          if extensions.any?
            @extensions ||= []
            @extensions.concat(extensions.map(&:to_sym)).uniq
          else
            @extensions
          end
        end
      end
    end

    # @api private
    class ProcessorCaller
      def initialize(instances)
        @processors = normalize(instances)
      end

      def process(content, extension)
        processors_for_extension(extension).each do |processor|
          content = processor.call(content)
        end

        unless extension == :html
          processors_for_extension(:html).each do |processor|
            content = processor.call(content)
          end
        end

        content
      end

      def process?(extension)
        @processors.key?(extension.tr(".", "").to_sym)
      end

      private

      def processors_for_extension(extension)
        @processors[extension] || []
      end

      def normalize(instances)
        instances.each_with_object({}) { |instance, processors|
          instance.class.extensions.each do |extension|
            (processors[extension] ||= []) << instance
          end
        }
      end
    end
  end
end
