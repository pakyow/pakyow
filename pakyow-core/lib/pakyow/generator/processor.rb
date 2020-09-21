# frozen_string_literal: true

require "erb"

module Pakyow
  class Generator
    # @api private
    class Processor
      class << self
        def reduce_path(path)
          case path.extname
          when ".erb"
            path.dirname.join(path.basename(".erb"))
          else
            path
          end
        end

        def process(content, context:)
          erb = if RUBY_VERSION.start_with?("2.5")
            ERB.new(content, trim_mode: "%<>-")
          else
            ERB.new(content, trim_mode: "%-")
          end

          erb.result(context.instance_eval { binding })
        end
      end
    end
  end
end
