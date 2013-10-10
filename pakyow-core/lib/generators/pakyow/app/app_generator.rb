require 'fileutils'
require File.expand_path('../../../../utils/dir', __FILE__)

module Pakyow
  module Generators
    class AppGenerator
      class << self
        def start
          case ARGV.first
          when '--help', '-h', nil
            puts File.open(File.join(CORE_PATH, 'commands/USAGE-NEW')).read
          else
            generator = self.new(ARGV.first)
            generator.build
          end
        end
      end

      def initialize(dest)
        @src = "#{File.expand_path('../', __FILE__)}/templates/."
        @dest = dest
      end

      def build
        puts "Generating \"#{@dest}\" project..."

        if !File.directory?(@dest) || (Dir.entries(@dest) - ['.', '..']).empty?
          copy
        else
          ARGV.clear
          print "The folder '#{@dest}' is in use. Would you like to populate it anyway? [Yn] "

          if gets.chomp! == 'Y'
            copy
          else
            puts "Aborted!"
            exit
          end
        end

        exec
      end

      protected

      # copies src files to dest
      def copy
        FileUtils.cp_r(@src, @dest)
        DirUtils.print_dir("#{@dest}")
      end

      # performs and other setup (e.g. bundle install)
      def exec
        puts "Running bundle install"
        `cd #{@dest} && bundle install`
      end
    end
  end
end
