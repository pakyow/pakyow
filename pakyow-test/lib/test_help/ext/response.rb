module Pakyow
  class Response
    def status
      Pakyow::TestHelp::MockStatus.new(@status)
    end
  end
end
