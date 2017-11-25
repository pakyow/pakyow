# frozen_string_literal: true

require "digest/sha1"
require "concurrent"

module Pakyow
  module Data
    class SubscriberStore
      module Adapter
        # Manages data subscriptions in memory.
        #
        # Great for development, not for use in production!
        #
        # @api private
        class Memory
          class << self
            def generate_subscription_id(subscription)
              Digest::SHA1.hexdigest(Marshal.dump(subscription))
            end
          end

          def initialize(_app_name, _config)
            @subscriptions_by_id = Concurrent::Hash.new
            @subscription_ids_by_model = Concurrent::Hash.new
            @subscription_ids_by_model_object_id = Concurrent::Hash.new
            @subscribers_by_subscription_id = Concurrent::Hash.new
            @subscription_ids_by_subscriber = Concurrent::Hash.new
            @expirations_for_subscriber = Concurrent::Hash.new
          end

          def register_subscription(subscription, subscriber: nil, object_ids: [])
            subscription_id = self.class.generate_subscription_id(subscription)
            register_subscription_with_subscription_id(subscription, subscription_id)
            register_model_object_ids_for_subscription_id(subscription[:model], object_ids, subscription_id)
            register_subscription_id_for_model(subscription_id, subscription[:model])
            register_subscriber_for_subscription_id(subscriber, subscription_id)
          end

          def update_model_object_ids_for_subscription_id(model, object_ids, subscription_id)
            register_model_object_ids_for_subscription_id(model, object_ids, subscription_id)
          end

          def subscriptions_for_model(model)
            subscription_ids_for_model(model).map { |subscription_id|
              subscription_with_id(subscription_id)
            }
          end

          def subscriptions_for_model_object(model, object_id)
            subscription_ids_for_model_object(model, object_id).map { |subscription_id|
              subscription_with_id(subscription_id)
            }
          end

          def unsubscribe(subscriber)
            subscription_ids_for_subscriber(subscriber).each do |subscription_id|
              unsubscribe_subscriber_from_subscription_id(subscriber, subscription_id)
            end
          end

          def expire(subscriber, seconds)
            task = Concurrent::ScheduledTask.execute(seconds) {
              unsubscribe(subscriber)
            }

            @expirations_for_subscriber[subscriber] ||= []
            @expirations_for_subscriber[subscriber] << task
          end

          def persist(subscriber)
            (@expirations_for_subscriber[subscriber] || []).each(&:cancel)
            @expirations_for_subscriber.delete(subscriber)
          end

          def expiring?(subscriber)
            @expirations_for_subscriber[subscriber]&.positive?
          end

          def subscribers_for_subscription_id(subscription_id)
            @subscribers_by_subscription_id[subscription_id] || []
          end

          protected

          def subscription_ids_for_model(model)
            @subscription_ids_by_model[model] || []
          end

          def subscription_ids_for_model_object(model, object_id)
            @subscription_ids_by_model_object_id.dig(model, object_id) || []
          end

          def subscription_with_id(subscription_id)
            subscription = @subscriptions_by_id[subscription_id].dup
            subscription[:id] = subscription_id
            subscription
          end

          def subscription_ids_for_subscriber(subscriber)
            @subscription_ids_by_subscriber[subscriber] || []
          end

          def register_subscription_with_subscription_id(subscription, subscription_id)
            @subscriptions_by_id[subscription_id] = subscription
          end

          def register_model_object_ids_for_subscription_id(model, object_ids, subscription_id)
            object_ids.each do |object_id|
              @subscription_ids_by_model_object_id[model] ||= Concurrent::Hash.new
              @subscription_ids_by_model_object_id[model][object_id] ||= Concurrent::Array.new
              (@subscription_ids_by_model_object_id[model][object_id] << subscription_id).uniq!
            end
          end

          def register_subscription_id_for_model(subscription_id, model)
            @subscription_ids_by_model[model] ||= Concurrent::Array.new
            (@subscription_ids_by_model[model] << subscription_id).uniq!
          end

          def register_subscriber_for_subscription_id(subscriber, subscription_id)
            @subscribers_by_subscription_id[subscription_id] ||= Concurrent::Array.new
            (@subscribers_by_subscription_id[subscription_id] << subscriber).uniq!

            @subscription_ids_by_subscriber[subscriber] ||= Concurrent::Array.new
            (@subscription_ids_by_subscriber[subscriber] << subscription_id).uniq!
          end

          def unsubscribe_subscriber_from_subscription_id(subscriber, subscription_id)
            subscribers_for_subscription_id(subscription_id).delete(subscriber)
            subscription_ids_for_subscriber(subscriber).delete(subscription_id)

            if subscribers_for_subscription_id(subscription_id).empty?
              @subscriptions_by_id.delete(subscription_id)

              @subscription_ids_by_model.each do |_, ids|
                ids.delete(subscription_id)
              end

              @subscription_ids_by_model_object_id.each do |_, object_id_map|
                object_id_map.each do |_, ids|
                  ids.delete(subscription_id)
                end
              end
            end
          end
        end
      end
    end
  end
end
