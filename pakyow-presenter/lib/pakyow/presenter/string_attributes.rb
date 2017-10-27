require "forwardable"

require "pakyow/support/deep_dup"

module Pakyow
  module Presenter
    # @api private
    class StringAttributes
      IGNORED = %i[container partial].freeze
      OPENING = '="'.freeze
      CLOSING = '"'.freeze
      SPACING = " ".freeze

      using Support::DeepDup

      extend Forwardable
      def_delegators :@attributes_hash, :keys, :[], :[]=, :delete, :each, :key?

      def initialize(attributes_hash = {})
        @attributes_hash = attributes_hash
      end

      def initialize_copy(_)
        @attributes_hash = @attributes_hash.deep_dup
      end

      def to_s
        # FIXME: assuming we can't mutate the structure with compact!, but needs more thought
        string = @attributes_hash.compact.map { |name, value|
          name.to_s + OPENING + value.to_s + CLOSING
        }.join(SPACING)

        if string.empty?
          string
        else
          SPACING + string
        end
      end
    end
  end
end
