module Pakyow
  before :setup do
    config.middleware.default.each do |middleware|
      use middleware
    end

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
    use Middleware::Logger
  end
end
