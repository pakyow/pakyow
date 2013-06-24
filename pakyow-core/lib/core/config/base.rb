module Pakyow
  module Config
    class Base
      @@configs = {}
      def self.register_config(name, klass)
        @@configs[name] = klass

        define_singleton_method name do
          @@configs[name]
        end
      end

      # Resets all config
      def self.reset!
        @@configs.keys.each do |type|
          klass = self.send(type.to_sym)
          klass.instance_variables.each do |var|
            # Assumes path shouldn't be reset, since it's only set
            # once when Pakyow::Application is inherited.
            next if var.to_sym == :'@path'
            begin
              klass.send("#{var.to_s.gsub('@', '')}=", nil)
            rescue
            end
          end
        end
      end
    end
  end
end
