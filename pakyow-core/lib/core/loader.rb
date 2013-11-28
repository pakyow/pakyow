module Pakyow
  # Handles the loading and reloading of a Pakyow application. If in development
  # mode, files are automatically reloaded if modified.
  class Loader

    # Loads files in the provided path, decending into child directories.
    def load_from_path(path)
      require_recursively(path)
    end

    protected

    def require_recursively(dir)
      @times ||= {}
      if File.exists?(dir)
        Utils::Dir.walk_dir(dir) do |path|
          next if FileTest.directory?(path)
          next if path.split('.')[-1] != 'rb'

          if Config::Base.app.auto_reload
            if !@times[path] || (@times[path] && File.mtime(path) - @times[path] > 0)
              load(path)
              @times[path] = File.mtime(path)
            end
          else
            require path
          end
        end
      end
    end
  end
end
