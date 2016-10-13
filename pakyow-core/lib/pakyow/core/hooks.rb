module Pakyow
  before :setup do
    # TODO: move these into a config option
    use Rack::MethodOverride
    use Rack::Head
    use Rack::ContentLength

    # TODO: make this opt-in
    # if Config.app.enforce_www
    #   use Middleware::WWWEnforcer
    # else
    #   use Middleware::NonWWWEnforcer
    # end

    # TODO: I'd like a normalizer enabled option
    # that controls this and www / non; maybe
    # even combine them into a single normalizer
    use Middleware::ReqPathNormalizer

    if Config.session.enabled
      use Config.session.object, Config.session.options
    end

    if Config.app.static
      use Middleware::Static
    end

    use Middleware::Logger
  end

  CallContext.after :error do
    logger.houston(req.error)
  end
end
