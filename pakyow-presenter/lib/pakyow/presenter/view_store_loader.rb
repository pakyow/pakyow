module Pakyow
  module Presenter
    # TODO: refactor this to one instance per app instead of singleton
    class ViewStoreLoader
      include Singleton

      def initialize
        @last_mod = {}
      end

      def modified?(name, paths)
        paths = Array.ensure(paths)

        if !@last_mod.key?(name)
          modified(name)
          return true
        end

        paths.each do |path|
          Dir.walk(path) do |p|
            next if FileTest.directory?(p)

            if File.mtime(p) > @last_mod[name]
              modified(name)
              return true
            end
          end
        end

        false
      end

      def reset
        @last_mod = {}
      end

      private

      def modified(name)
        @last_mod[name] = Time.now
      end
    end
  end
end
