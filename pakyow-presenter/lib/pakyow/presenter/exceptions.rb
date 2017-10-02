module Pakyow
  module Presenter
    class FrontMatterParsingError < Error; end
    class MissingTemplatesDir < Error; end
    class MissingView < Error; end
    class MissingTemplate < Error; end
    class MissingPage < Error; end
    class MissingPartial < Error; end
    class MissingComposer < Error; end
    class MissingContainer < Error; end
  end
end
