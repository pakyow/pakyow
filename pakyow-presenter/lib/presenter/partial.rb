module Pakyow
  module Presenter
    class Partial
      include DocHelpers

      class << self
        def load(path)
          format    = StringUtils.split_at_last_dot(path)[-1]
          contents  = File.read(path)
          name      = File.basename(path, '.*')[1..-1].to_sym

          return self.new(name, contents, format)
        end
      end

      def initialize(name, contents, format = :html)
        @name = name

        processed = Presenter.process(contents, format)
        @doc = Nokogiri::HTML.fragment(processed)
      end
    end
  end
end
