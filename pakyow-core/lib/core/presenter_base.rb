module Pakyow
  class PresenterBase
    def self.inherited(subclass)
      Configuration::Base.app.presenter = subclass
    end
  end
end