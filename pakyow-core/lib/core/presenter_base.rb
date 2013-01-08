module Pakyow
  class PresenterBase
    def self.inherited(subclass)
      Configuration::Base.app.presenter = subclass
    end

    def self.instance
      @@instance ||= self.new
    end
  end
end