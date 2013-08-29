module Pakyow
  module AppHelpers
    def mailer(view_path)
      Mailer.new(view_path, @presenter.store)
    end
  end
end
