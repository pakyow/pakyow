require 'fileutils'

module Pakyow
  module Generators
    class AppGenerator
      class << self
        def start
          case ARGV.first
          when '--help', '-h', nil
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
        if !File.directory?(dest) || (Dir.entries(dest) - ['.', '..']).empty?
          FileUtils.cp_r(@src, dest)
        else
          ARGV.clear
          print "The folder '#{dest}' is in use. Would you like to populate it anyway? [Yn] "

          if gets.chomp! == 'Y'
            FileUtils.cp_r(@src, dest)
          end
        end
      end
    end
  end
end
