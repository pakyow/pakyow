require "pakyow/middleware/json_body"
require "pakyow/middleware/req_path_normalizer"
require "pakyow/middleware/logger"

module Pakyow
  before :setup do
    use Rack::ContentType, "text/html;charset=utf-8"
    use Rack::ContentLength
    use Rack::Head
    use Rack::MethodOverride

    # TODO: make this opt-in
    # if Config.app.enforce_www
    #   use Middleware::WWWEnforcer
    # else
    #   use Middleware::NonWWWEnforcer
    # end

    # TODO: I'd like a normalizer enabled option
    # that controls this and www / non; maybe
    # even combine them into a single normalizer
    use Middleware::JSONBody
    use Middleware::ReqPathNormalizer
    use Middleware::Logger
  end
end
