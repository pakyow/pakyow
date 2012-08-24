module Pakyow
  module Presenter
    class Binder
      include Pakyow::GeneralHelpers

      class << self
        attr_accessor :options
        
        def binder_for(*args)
          View.binders ||= {}
          args.each { |klass| View.binders[klass.to_s.to_sym] = self }
        end
        
        def options_for(*args)
          self.options = {} unless self.options
          self.options[args[0]] = args[1]
        end
      end
      
      attr_accessor :bindable
      
      def initialize(bindable)
        self.bindable = bindable
      end

      def value_for_prop(prop)
        self.class.method_defined?(prop) ? self.send(prop) : bindable[prop]
      end
      
      def fetch_options_for(attribute)
        if self.class.options
          if options = self.class.options[attribute]
            unless options.is_a?(Array) || options.is_a?(Hash)
              options = self.send(options)
            end
          
            return options
          end
        end
      end
    end
  end
end
