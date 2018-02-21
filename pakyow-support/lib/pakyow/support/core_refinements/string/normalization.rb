# frozen_string_literal: true

module Pakyow
  module Support
    module Refinements
      module String
        module Normalization
          refine ::String.singleton_class do
            # Normalizes a string into a predictable path.
            #
            #   String.normalize_path("foo//bar/")
            #   # => "/foo/bar"
            #
            def normalize_path(path)
              File.join("/", path.to_s.gsub("//", "/").chomp("/"))
            end
          end
        end
      end
    end
  end
end
