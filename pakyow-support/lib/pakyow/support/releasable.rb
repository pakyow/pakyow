# frozen_string_literal: true

require_relative "class_state"
require_relative "extension"

module Pakyow
  module Support
    # Manages how code is released to end-users through risk-associated release channels.
    #
    # Release channels are defined on an object, each with a certain risk. Code blocks defined for
    # a channel is available only when the end-user adopts an acceptable risk profile.
    #
    # @example
    #   class SomeObject
    #     include Pakyow::Support::Releasable
    #
    #     release_channel :alpha, risk: 20
    #     release_channel :beta, risk: 10
    #
    #     releasable :alpha do
    #       def some_alpha_behavior
    #         :alpha
    #       end
    #     end
    #
    #     releasable :beta do
    #       def some_beta_behavior
    #         :beta
    #       end
    #     end
    #   end
    #
    #   SomeObject.release_channel = :beta
    #
    #   instance = SomeObject.new
    #
    #   instance.some_alpha_behavior
    #   => NoMethodError
    #
    #   instance.some_beta_behavior
    #   => :beta
    #
    module Releasable
      extend Extension

      extend_dependency ClassState

      class UnknownReleaseChannel < ArgumentError
      end

      apply_extension do
        class_state :__release_channels, default: {default: 0}, inheritable: true
        class_state :__risk_tolerance, default: nil, inheritable: true
        class_state :__releasables, default: [], inheritable: true
      end

      class_methods do
        # Define a release channel with a particular risk.
        #
        def release_channel(channel, risk:)
          __release_channels[channel.to_sym] = risk.to_i
        end

        # Returns the known release channels.
        #
        def release_channels
          __release_channels.keys
        end

        # Returns true if `channel` is a known release channel.
        #
        def release_channel?(channel)
          __release_channels.include?(channel.to_sym)
        end

        # Sets the current release channel.
        #
        def release_channel=(channel)
          if release_channel?(channel)
            @__risk_tolerance = risk_for_channel(channel)
            apply_releasables!
          else
            raise UnknownReleaseChannel, "unknown release channel `#{channel}'"
          end
        end

        # Defines some releasable code for `channel`. Code will be evaled when the release channel
        # is set on the object, or immediately if the release channel is already set.
        #
        def releasable(channel = nil, &block)
          if __risk_tolerance.nil?
            __releasables << [risk_for_channel(channel), block]
          elsif releasable?(channel)
            class_eval(&block)
          end
        end

        private def releasable?(channel)
          release_channel?(channel) && (risk_for_channel(channel) <= __risk_tolerance)
        end

        private def risk_for_channel(channel)
          __release_channels[channel.to_sym]
        end

        private def apply_releasables!
          __releasables.select { |risk, _|
            risk <= __risk_tolerance
          }.each do |_, block|
            class_eval(&block)
          end
        end
      end
    end
  end
end
