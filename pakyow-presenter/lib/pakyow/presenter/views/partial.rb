module Pakyow
  module Presenter
    class Partial < View
      attr_accessor :name

      class << self
        def load(path, content: nil)
          name = File.basename(path, ".*")
          name = name[1..-1] if name.start_with?("_")
          self.new(name.to_sym, content || File.read(path))
        end
      end

      def initialize(name, html = "")
        @name = name
        super(html)
      end
    end
  end
end
