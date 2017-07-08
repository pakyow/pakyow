require "forwardable"

module Pakyow
  module Presenter
    # @api private
    class StringAttributes
      extend Forwardable

      def_delegators :@attributes_hash, :keys, :[], :[]=, :delete

      def initialize(attributes_hash = {})
        @attributes_hash = attributes_hash
      end

      IGNORED = %i[container partial].freeze
      OPENING = '="'.freeze
      CLOSING = '"'.freeze
      SPACING = " ".freeze

      def to_s
        @attributes_hash.delete_if { |a| a.nil? || IGNORED.include?(a) }.map { |attr|
          attr[0].to_s + OPENING + attr[1].to_s + CLOSING
        }.join(SPACING)
      end
    end
  end
end
