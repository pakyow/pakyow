require "smoke_helper"

RSpec.describe "routing requests", smoke: true do
  before do
    setup; boot
  end

  def setup
    root_controller_path = backend_path.join("controllers/root.rb")
    FileUtils.mkdir_p(root_controller_path.dirname)

    File.open(root_controller_path, "w+") do |file|
      file.write <<~SOURCE
        controller do
          default do
            send "foo"
          end
        end
      SOURCE
    end
  end

  let(:backend_path) {
    project_path.join("backend")
  }

  it "responds to a request" do
    response = http.get("http://localhost:#{port}")

    expect(response.status).to eq(200)
    expect(response.body.to_s).to eq("foo")
  end

  context "non-standard backend path" do
    def setup
      super

      File.open(project_path.join("config/application.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.app :smoke_test do
            configure do
              config.src = File.join(config.root, "custom-backend")
            end
          end
        SOURCE
      end
    end

    let(:backend_path) {
      project_path.join("custom-backend")
    }

    it "responds to a request" do
      response = http.get("http://localhost:#{port}")

      expect(response.status).to eq(200)
      expect(response.body.to_s).to eq("foo")
    end
  end
end
