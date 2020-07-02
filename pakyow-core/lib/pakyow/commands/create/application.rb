# frozen_string_literal: true

require "fileutils"

command :create, :application do
  describe "Create a new application in the current project"
  required :cli

  argument :name, "The application name", required: true
  option :path, "The mount path for the created application", default: "/"
  option :template, "The template to create the application from", default: "default"

  action :relocate_default_application do
    next if default_app.nil?

    if default_application_config_file_path.exist?
      verify_path_within_root!(default_multiapp_application_config_path)
      FileUtils.mkdir_p(default_multiapp_application_config_path)
      FileUtils.mv(default_application_config_file_path, default_multiapp_application_config_path)
    end

    if default_multiapp_application_config_path.exist?
      verify_path_within_root!(default_multiapp_application_config_path)
      FileUtils.mkdir_p(default_multiapp_application_initializers_path)
      relocate(default_application_initializers_path, default_multiapp_application_initializers_path)
      FileUtils.rm_r(default_application_initializers_path)
    end

    if default_application_lib_path.exist?
      verify_path_within_root!(default_multiapp_application_lib_path)
      FileUtils.mkdir_p(default_multiapp_application_lib_path)
      relocate(default_application_lib_path, default_multiapp_application_lib_path)
      FileUtils.rm_r(default_application_lib_path)
    end

    if default_application_backend_path.exist?
      verify_path_within_root!(default_multiapp_application_backend_path)
      FileUtils.mkdir_p(default_multiapp_application_backend_path)
      relocate(default_application_backend_path, default_multiapp_application_backend_path)
      FileUtils.rm_r(default_application_backend_path)
    end
  end

  action :generate_application do
    template = @template.downcase.strip
    generator = case template
    when "default"
      Pakyow.generator(:application)
    else
      Pakyow.generator(:application, template.to_sym)
    end

    generatable_name = Generator::generatable_name(@name)
    generator.generate(multiapp_path.join(generatable_name), name: generatable_name, path: @path)
  end

  private def root_path
    Pathname.new(File.expand_path(Pakyow.config.root))
  end

  private def multiapp_path
    Pathname.new(File.expand_path(Pakyow.config.multiapp_path))
  end

  private def default_application_config_file_path
    root_path.join("config/application.rb")
  end

  private def default_application_initializers_path
    root_path.join("config/initializers/application")
  end

  private def default_application_lib_path
    Pathname.new(File.expand_path(default_app.config.lib))
  end

  private def default_application_backend_path
    Pathname.new(File.expand_path(default_app.config.src))
  end

  private def default_multiapp_application_path
    multiapp_path.join(default_app_name.to_s)
  end

  private def default_multiapp_application_config_path
    default_multiapp_application_path.join("config")
  end

  private def default_multiapp_application_initializers_path
    default_multiapp_application_config_path.join("initializers/application")
  end

  private def default_multiapp_application_lib_path
    default_multiapp_application_path.join(default_application_lib_path.relative_path_from(root_path))
  end

  private def default_multiapp_application_backend_path
    default_multiapp_application_path.join(default_application_backend_path.relative_path_from(root_path))
  end

  private def default_app_name
    default_app.config.name
  end

  private def default_app
    Pakyow.apps[0]
  end

  private def relocate(source, destination)
    source.glob("**/*").reject { |path|
      path.directory?
    }.each do |path|
      relative_path = path.relative_path_from(source)
      FileUtils.mkdir_p(destination.join(relative_path.dirname))
      FileUtils.mv(path, destination.join(relative_path))
    end
  end

  private def verify_path_within_root!(path)
    raise "project cannot be converted to multiapp because `#{path}' is not within `#{Pakyow.config.root}'" unless path_within_root?(path)
  end

  private def path_within_root?(path)
    File.expand_path(path).to_s.start_with?(root_path.to_s)
  end
end
