module Pakyow
  module Support
    module WalkDir
      DOT = ".".freeze

      refine Dir.singleton_class do
        # Yields each file in path, then files in child directories.
        #
        def walk(path, &block)
          yield path

          files, dirs = Dir.entries(path).partition { |entry|
            File.file?(File.join(path, entry))
          }

          files.each do |file|
            next if file.start_with?(DOT)
            yield File.join(path, file)
          end

          dirs.each do |dir|
            next if dir.start_with?(DOT)
            walk(File.join(path, dir), &block)
          end
        end

        def print(dir)
          puts "/#{dir}"
          Dir.walk(dir) {|full_path|
            path = full_path.gsub(Regexp.new("#{dir}\/?"), '')
            next if path.empty?

            prefix = "|"
            path.scan(/\//).size.times do
              prefix += "  |"
            end

            path.gsub!(/^.*\//, '')
            puts "#{prefix}-- #{path}"
          }
        end

        def within_dir?(dir1, dir2)
          (dir1.split('/') - dir2.split('/')).empty?
        end
      end
    end
  end
end
