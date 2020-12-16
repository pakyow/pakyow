require "bundler"
require "http"
require "fileutils"
require "securerandom"
require "timeout"

require "pakyow/support/system"

module SmokeContext
  extend RSpec::SharedContext

  let(:envars) {
    {}
  }

  let(:host) {
    "0.0.0.0"
  }

  let(:port) {
    Pakyow::Support::System.available_port
  }

  let(:environment) {
    :development
  }

  let(:project_path) {
    Pathname(@project_path)
  }

  let(:http) {
    HTTP.timeout(15)
  }
end

RSpec.configure do |config|
  config.include SmokeContext

  config.before :suite do
    install
  end

  config.before :all do
    @project_name = "smoke-test"
    @original_path = Dir.pwd
  end

  config.before do
    @working_path = File.join(@original_path, "smoke-#{SecureRandom.hex(4)}")
    @project_path = File.join(@working_path, @project_name)
    Dir.chdir(@original_path)
    create
  end

  config.after do
    sleep 5
    shutdown if booted?
    Dir.chdir(@original_path)
    FileUtils.rm_r(@working_path)
  end

  config.after :suite do
    clean
  end

  def install
    Bundler.with_original_env do
      system "bundle exec rake gems:install"
    end
  end

  def clean
    Bundler.with_original_env do
      system "bundle exec rake gems:clean"
    end
  end

  def create
    Timeout.timeout(60) do
      FileUtils.mkdir_p(@working_path)
      Dir.chdir(@working_path)

      Bundler.with_original_env do
        system "pakyow create #{@project_name}"
      end

      Dir.chdir(@project_path)
    end
  end

  def boot(environment: self.environment, envars: self.envars, port: self.port, host: self.host, wait: true, formation: nil)
    Timeout.timeout(60) do
      Bundler.with_original_env do
        command = if formation
          "pakyow boot -e #{environment} -p #{port} --host #{host} -f #{formation}"
        else
          "pakyow boot -e #{environment} -p #{port} --host #{host}"
        end

        @server = Process.spawn(envars, command)
      end

      if wait
        wait_for_boot do
          yield if block_given?
        end
      end
    end
  end

  def cli_run(*command, envars: self.envars)
    Timeout.timeout(60) do
      Bundler.with_original_env do
        Process.waitpid(Process.spawn(envars, "pakyow #{command.join(" ")}"))
        $?
      end
    end
  end

  def wait_for_boot(start = Time.now, timeout = 60)
    HTTP.get("http://localhost:#{port}")
    @boot_time = Time.now - start
    yield
  rescue HTTP::ConnectionError
    unless Time.now - start > timeout
      sleep 0.01
      retry
    end
  end

  def booted?
    defined?(@server)
  end

  def shutdown(signal = "INT")
    Timeout.timeout(60) do
      if booted?
        Process.kill(signal, @server)

        unless signal == "HUP"
          Process.waitpid(@server)
          remove_instance_variable(:@server)
        end
      end
    end
  end

  def ensure_bundled(gem_name)
    Timeout.timeout(60) do
      gemfile_path = project_path.join("Gemfile")

      unless gemfile_path.read.include?(gem_name)
        gemfile_path.open("a") do |file|
          file.write <<~SOURCE
            gem "#{gem_name}"
          SOURCE
        end

        Bundler.with_original_env do
          system "bundle install"
        end
      end
    end
  end
end
