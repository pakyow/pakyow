# frozen_string_literal: true

require "pakyow/support/inspectable"

module Pakyow
  module Runnable
    class Formation
      require_relative "formation/parser"

      class << self
        # Parses a formation string, returning a representative `Formation` instance.
        #
        def parse(string)
          return string if string.is_a?(Formation)
          Parser.new(string).formation
        end

        # Returns a formation representing all services.
        #
        def all(count = nil)
          All.build { |formation|
            formation.run(:all, count)
          }
        end

        # Builds a formation.
        #
        def build(container = nil)
          instance = self.new(container)
          yield instance if block_given?
          instance
        end
      end

      include Support::Inspectable
      inspectable :@container, :@services, :@formations

      # Define this after inspectable so that it correctly inherits class-level state.
      #
      require_relative "formation/all"

      attr_reader :container

      # @api private
      attr_writer :parent

      def initialize(container = nil)
        @container = container&.to_sym
        @services = {}
        @formations = []
        @parent = nil
        @lock = Mutex.new
      end

      def initialize_copy(_)
        super

        @services = @services.dup
      end

      # Run `count` instances of `service` in this formation.
      #
      def run(service, count = nil)
        @lock.synchronize do
          @services[service.to_sym] = count ? count.to_i : nil
        end
      end

      # Add a nested formation to this formation.
      #
      def <<(formation)
        @lock.synchronize do
          @formations << formation
        end
      end

      # Builds a nested formation for `container`.
      #
      def build(container = nil, &block)
        formation = self.class.build(container, &block)
        formation.parent = self
        self << formation
      end

      # Merges `formation` with this formation.
      #
      def merge!(formation)
        formation.each do |service, count|
          run(service, count)
        end

        formation.each_formation.each do |nested_formation|
          if existing_nested = formation(nested_formation.container)
            existing_nested.merge!(nested_formation)
          else
            self << nested_formation
          end
        end
      end

      # Returns `true` if `service` is a known service.
      #
      def service?(service)
        @services.include?(service.to_sym)
      end

      # Returns the count for `service`.
      #
      def count(service)
        @services[service.to_sym]
      end

      # Returns `true` if a nested formation exists for `container`.
      #
      def formation?(container)
        container = container.to_sym
        @formations.any? { |formation| formation.container == container }
      end

      # Returns the nested formation for `container`.
      #
      def formation(container)
        container = container.to_sym
        @formations.find { |formation| formation.container == container }
      end

      # Yields each service and respective count.
      #
      def each(&block)
        return enum_for(:each) unless block_given?

        @services.each_pair(&block)
      end

      # Yields each service.
      #
      def each_service(&block)
        return enum_for(:each_service) unless block_given?

        @services.each_key(&block)
      end

      # Yields each nested formation.
      #
      def each_formation(&block)
        return enum_for(:each_formation) unless block_given?

        @formations.each(&block)
      end

      # Returns a string representation of this formation.
      #
      def to_s
        @services.each_with_object([]) { |(service, count), formations|
          formation = if count.nil?
            service
          else
            "#{service}=#{count}"
          end

          formations << [path, formation].reject { |part| part.nil? || part.empty? }.join(".")
        }.concat(@formations.flat_map(&:to_s)).join(",")
      end

      def ==(other)
        other.to_s == to_s
      end

      # Returns the path to this formation.
      #
      # @api private
      def path
        [@parent&.path, @container].compact.join(".")
      end
    end
  end
end
