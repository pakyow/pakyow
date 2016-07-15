module Pakyow
  module UI
    # Helpers for building channel names.
    #
    # @api private
    module ChannelBuilder
      PARTS = [:scope, :mutation, :component]

      def self.build(qualifiers: [], data: [], qualifications: {}, **args)
        channel = []
        channel_extras = []

        PARTS.each do |part|
          add_part(part, args[part], channel)
        end

        add_qualifiers(qualifiers, data, channel_extras)
        add_qualifications(qualifications, channel_extras)

        channel = channel.join(';')

        return channel if channel_extras.empty?
        channel << "::#{channel_extras.join(';')}"
      end

      private

      def self.add_part(part, value, channel)
        return if value.nil?
        channel << "#{part}:#{value}"
      end

      def self.add_qualifiers(qualifiers, data, channel_extras)
        qualifiers = Array.ensure(qualifiers)

        data = data.data if data.is_a?(Pakyow::UI::MutableData)
        data = Array.ensure(data).compact
        return if qualifiers.empty? || data.empty?

        datum = data.first

        qualifiers.each do |qualifier|
          channel_extras << "#{qualifier}:#{datum[qualifier.to_sym]}"
        end
      end

      def self.add_qualifications(qualifications, channel_extras)
        qualifications.each do |name, value|
          next if value.nil?
          channel_extras << "#{name}:#{value}"
        end
      end
    end
  end
end
