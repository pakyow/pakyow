module Pakyow
  module Helpers
    def mailer(view_path)
      Mailer.from_store(view_path, @presenter.store, self)
    end
  end
end
