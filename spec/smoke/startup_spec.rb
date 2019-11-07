require "bundler"
require "http"
require "fileutils"

require "pakyow/processes/proxy"

RSpec.describe "starting up a newly generated project", smoke: true do
  def install
    Bundler.with_clean_env do
      system "bundle exec rake release:install"
    end
  end

  def create
    @original_path = Dir.pwd
    FileUtils.mkdir_p(@working_path)
    Dir.chdir(@working_path)
    system "pakyow create #{@project_name}"
    Dir.chdir(@project_path)
  end

  def boot(environment, envars, port, host)
    @server = Process.spawn(envars, "pakyow boot -e #{environment} -p #{port} --host #{host}")

    wait_for_boot do
      yield
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

  before :all do
    @project_name = "smoke-test"
    @working_path = File.expand_path("../tmp", __FILE__)
    @project_path = File.join(@working_path, @project_name)

    install
    create
  end

  after :all do
    Dir.chdir(@original_path)
    system "bundle exec rake release:clean"
    FileUtils.rm_r(@working_path)
  end

  before do
    boot(environment, envars, port, "0.0.0.0") do
      # TODO: Enable this once externals are fetched in the background.
      #
      # expect(@boot_time).to be < 10
    end
  end

  after do
    Process.kill("TERM", @server)
    Process.waitpid(@server)
  end

  let :envars do
    {}
  end

  let :port do
    Pakyow::Processes::Proxy.find_local_port
  end

  context "development environment" do
    let :environment do
      :development
    end

    it "responds to a request" do
      response = HTTP.get("http://localhost:#{port}")

      # It'll 404 because of the default view missing message. This is fine.
      #
      expect(response.status).to eq(404)
    end
  end

  context "production environment" do
    let :environment do
      :production
    end

    let :envars do
      {
        "SECRET" => "sekret",
        "DATABASE_URL" => "sqlite://database/production.db"
      }
    end

    it "responds to a request" do
      response = HTTP.get("http://localhost:#{port}")

      # It'll 404 because of the default view missing message. This is fine.
      #
      expect(response.status).to eq(404)
    end
  end
end
