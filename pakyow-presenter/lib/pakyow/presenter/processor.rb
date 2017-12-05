# frozen_string_literal: true

module Pakyow
  module Presenter
    class ProcessorCaller
      def initialize(instances)
        @processors = normalize(instances)
      end

      def process(path)
        content   = File.read(path)
        extension = File.extname(path).delete(".").to_sym

        processors_for_extension(extension).each do |processor|
          content = processor.process(content)
        end

        unless extension == :html
          processors_for_extension(:html).each do |processor|
            content = processor.process(content)
          end
        end

        content
      end

      protected

      def processors_for_extension(extension)
        @processors[extension] || []
      end

      def normalize(instances)
        instances.each_with_object({}) { |instance, processors|
          instance.extensions.each do |extension|
            (processors[extension] ||= []) << instance
          end
        }
      end
    end

    class Processor
      extend Support::Makeable

      class << self
        attr_reader :name, :extensions, :block

        def make(name, *extensions, **kwargs, &block)
          # name is expected to also be an extension
          extensions.unshift(name).map!(&:to_sym)
          super(name, extensions: extensions, block: block, **kwargs) {}
        end

        def process(content)
          block.call(content)
        end
      end
    end
  end
end
