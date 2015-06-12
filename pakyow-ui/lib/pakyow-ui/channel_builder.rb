module Pakyow
  module UI
    module ChannelBuilder
      def self.build(scope: nil, mutation: nil, component: nil, qualifiers: [], data: [], qualifications: {})
        channel = []
        channel << "scope:#{scope}" unless scope.nil?
        channel << "mutation:#{mutation}" unless mutation.nil?
        channel << "component:#{component}" unless component.nil?

        channel_qualifiers = []
        qualifiers = Array.ensure(qualifiers)
        unless qualifiers.empty? || data.empty?
          datum = Array.ensure(data).first
          qualifiers.inject(channel) do |channel, qualifier|
            channel_qualifiers << "#{qualifier}:#{datum[qualifier]}"
          end
        end

        qualifications.each do |name, value|
          next if value.nil?
          channel_qualifiers << "#{name}:#{value}"
        end

        channel = channel.join(';')

        if !channel_qualifiers.empty?
          channel << "::#{channel_qualifiers.join(';')}"
        end

        channel
      end
    end
  end
end
