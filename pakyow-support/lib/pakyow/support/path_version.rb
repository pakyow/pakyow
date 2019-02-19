# frozen_string_literal: true

require "digest/sha1"

module Pakyow
  module Support
    class PathVersion
      # Builds a version based on content at local paths.
      #
      def self.build(*paths)
        paths.each_with_object(Digest::SHA1.new) { |path, digest|
          Dir.glob(File.join(path, "/**/*")).sort.each do |fullpath|
            if File.file?(fullpath)
              digest.update(Digest::SHA1.file(fullpath).to_s)
            end
          end
        }.to_s
      end
    end
  end
end
