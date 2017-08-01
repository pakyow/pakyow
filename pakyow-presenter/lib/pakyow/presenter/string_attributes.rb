require "forwardable"

module Pakyow
  module Presenter
    # @api private
    class StringAttributes
      IGNORED = %i[container partial].freeze
      OPENING = '="'.freeze
      CLOSING = '"'.freeze
      SPACING = " ".freeze

      extend Forwardable

      def_delegators :@attributes_hash, :keys, :[], :[]=, :delete

      def initialize(attributes_hash = {})
        @attributes_hash = attributes_hash
      end

      def to_s
        # FIXME: assuming we can't mutate the structure with compact!, but needs more thought
        @attributes_hash.compact.map { |attr|
          attr[0].to_s + OPENING + attr[1].to_s + CLOSING
        }.join(SPACING)
      end
    end
  end
end
