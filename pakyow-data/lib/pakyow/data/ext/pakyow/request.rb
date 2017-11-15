require "pakyow/data/verification"

module Pakyow
  class Request
    include Data::Verification
    verifies :params
  end
end
