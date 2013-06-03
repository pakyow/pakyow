module Pakyow
  module Presenter
    # A singleton that manages route sets.
    #
    class Binder
      include Singleton
      include Pakyow::GeneralHelpers

      attr_reader :sets

      def initialize
        @sets = {}
      end

      #TODO want to do this for all sets?
      def reset
        @sets = {}
        self
      end
      
      # Creates a new set.
      #
      def set(name, &block)
        @sets[name] = BinderSet.new
        @sets[name].instance_exec(&block)
      end

      def value_for_prop(*args)
        match = nil
        @sets.each {|set|
          match = set[1].value_for_prop(*args)
          break if match
        }

        return match
      end

      def options_for_prop(*args)
        match = nil
        @sets.each {|set|
          match = set[1].options_for_prop(*args)
          break if match
        }

        return match
      end

      def has_prop?(*args)
        has = nil
        @sets.each {|set|
          has = set[1].has_prop?(*args)
          break if has
        }

        return has
      end
    end
  end
end
