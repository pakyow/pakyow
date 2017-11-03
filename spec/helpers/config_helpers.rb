module ConfigHelpers
  def config_defaults(config, env)
    Pakyow::Support::Configurable::ConfigGroup.new(
      config.name,
      config.options,
      config.parent,
      &config.defaults(env)
    )
  end
end
