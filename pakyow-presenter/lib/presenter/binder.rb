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
      
      attr_accessor :bindable, :object
      
      def initialize(bindable, object)
        self.bindable = bindable
        self.object = object
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
