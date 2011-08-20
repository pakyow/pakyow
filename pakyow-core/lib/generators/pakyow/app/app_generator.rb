require 'fileutils'

module Pakyow
  module Generators
    class AppGenerator
      class << self
        def start
          if ARGV.first == '--help' || ARGV.first == '-h'
            puts File.open(File.join(CORE_PATH, 'commands/USAGE-NEW')).read
          else
            generator = self.new
            generator.build(ARGV.first)
          end
        end
      end
      
      def initialize
        @src = "#{File.expand_path('../', __FILE__)}/templates/."
      end
      
      def build(dest)
        FileUtils.cp_r(@src, dest)
      end
    end
  end
end
