module Pakyow
  module AppHelpers
    def mailer(view_path)
      Mailer.from_store(view_path, @presenter.store)
    end
  end
end
