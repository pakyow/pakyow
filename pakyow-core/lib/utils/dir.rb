module Pakyow

  # Utility methods for directories and files.
  class DirUtils

      # visit dir, then all files in dir, then walk_dir each directory in dir
      def self.walk_dir(dir, &block)
        yield dir
        all = Dir.entries(dir)
        partition = all.partition{|e| File.file?("#{dir}/#{e}")}
        files = partition[0]
        dirs = partition[1]
        files.each{|f| yield "#{dir}/#{f}" unless f.start_with?(".")}
        dirs.each{|d| walk_dir("#{dir}/#{d}", &block) unless d.start_with?(".")}
      end

  end
end
