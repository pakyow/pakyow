# frozen_string_literal: true

# Configures bootsnap.
#
begin
  require "bootsnap"

  Bootsnap.setup(
    cache_dir: File.join(Pakyow.config.root, "tmp/cache"),
    development_mode: Pakyow.env?(:development),
    load_path_cache: true,
    autoload_paths_cache: false,
    disable_trace: false,
    compile_cache_iseq: true,
    compile_cache_yaml: true
  )
rescue LoadError
end
