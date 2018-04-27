# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/inspectable"

module Pakyow
  module Data
    class Proxy
      class << self
        def deserialize(info, proxy)
          info[:proxied_calls].each do |proxied_call|
            proxy = proxy.public_send(proxied_call[:call], *proxied_call[:args])
          end

          proxy
        end
      end

      include Support::Inspectable
      inspectable :source

      using Support::Refinements::Array::Ensurable

      attr_reader :source, :proxied_calls

      def initialize(source, subscribers)
        @source, @subscribers = source, subscribers
        @proxied_calls = []
        @subscribable = true
      end

      def method_missing(method_name, *args, &block)
        if @source.command?(method_name)
          @source.command(method_name).call(*args, &block).tap { |result|
            @subscribers.did_mutate(
              @source.class.__class_name.name,
              args[0],
              Array.ensure(result).compact
            )
          }
        elsif @source.query?(method_name)
          dup.tap { |proxy|
            proxy.instance_variable_set(:@source, @source.public_send(method_name, *args, &block))
            proxy.instance_variable_get(:@proxied_calls) << {
              call: method_name,
              args: args
            }
          }
        elsif @source.result?(method_name) || @source.modifier?(method_name)
          # TODO: shouldn't this be returning a new proxy, proxied calls, etc?

          if block_given? && @source.block_for_nested_source?(method_name)
            # In this case a block has been passed that would, without intervention,
            # be called in context of a source instance. We don't want that, since
            # it would provide full access to the underlying dataset. Instead the
            # exposed object should simply be another proxy.

            local_subscribers = @subscribers
            @source.public_send(method_name, *args) {
              tap { |source|
                Proxy.new(source, local_subscribers).instance_exec(&block)
              }
            }
          else
            @source.public_send(method_name, *args, &block)
          end
        else
          super
        end
      end

      def respond_to_missing?(method_name, *)
        @source.command?(method_name) || @source.query?(method_name) ||
          @source.result?(method_name) || @source.modifier?(method_name)
      end

      def subscribe(subscriber, handler:, payload: nil)
        subscription_ids = []

        if subscribable?
          qualifications = @proxied_calls.inject({}) { |qualifications, proxied_call|
            qualifications_for_proxied_call = @source.model.qualifications(proxied_call[:call])

            # Populate argument qualifications with argument values.
            #
            qualifications_for_proxied_call.each do |qualification_key, qualification_value|
              next unless qualification_value.to_s.start_with?("__arg")
              arg_number = qualification_value.to_s.gsub(/[^0-9]/, "").to_i
              qualifications_for_proxied_call[qualification_key] = proxied_call[:args][arg_number]
            end

            qualifications.merge(qualifications_for_proxied_call)
          }

          primary_key = @source.model.primary_key_field

          result_pks_target = if @source.__getobj__.is_a?(ROM::Relation::Combined)
            @source.__getobj__.root
          elsif @source.__getobj__.is_a?(ROM::Relation::Composite)
            @source.__getobj__.left
          else
            @source
          end

          result_pks = result_pks_target.select(primary_key).map { |object|
            object[primary_key]
          }

          subscription = {
            model: @source.model.__class_name.name,
            handler: handler,
            payload: payload,
            qualifications: qualifications,
            subscriber: subscriber,
            pk_field: primary_key,
            object_pks: result_pks,
            proxy: to_h
          }

          subscription_ids << @subscribers.register_subscription(subscription, subscriber: subscriber)

          # Register subscriptions for any combined models.
          #
          if @source.__getobj__.is_a?(ROM::Relation::Combined)
            result_pks.each do |result_pk_value|
              nodes.each do |node|
                combined_subscription = {
                  model: node.name.to_sym,
                  handler: handler,
                  payload: payload,
                  qualifications: {
                    :"#{Support.inflector.singularize(@source.model.__class_name.name)}_#{primary_key}" => result_pk_value
                  },
                  proxy: to_h
                }

                subscription_ids << @subscribers.register_subscription(combined_subscription, subscriber: subscriber)
              end
            end
          end
        end

        subscription_ids
      end

      def subscribable(boolean)
        tap do
          @subscribable = boolean
        end
      end

      def subscribable?
        @subscribable == true
      end

      def to_h
        {
          model: @source.model.__class_name.name,
          proxied_calls: @proxied_calls
        }
      end
    end
  end
end
