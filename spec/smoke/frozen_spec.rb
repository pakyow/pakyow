require "smoke_helper"

RSpec.describe "changing application state at runtime", :repeatable, smoke: true do
  before do
    File.open(project_path.join("config/application.rb"), "w+") do |file|
      file.write <<~SOURCE
        Pakyow.app :smoke_test, only: %i[routing data] do
          controller "/mutate" do
            handle FrozenError, as: :internal_server_error do
              send "frozen"
            end

            namespace "/environment" do
              get "/config" do
                Pakyow.config.secrets << :hacked
              end
            end

            namespace "/application" do
              get "/config" do
                config.name = :hacked
              end

              get "/aspect" do
                connection.app.class.controller :foo do; end
              end
            end
          end
        end
      SOURCE
    end

    boot
  end

  context "changing environment config" do
    it "fails" do
      response = http.get("http://localhost:#{port}/mutate/environment/config")
      expect(response.body.to_s).to eq("frozen")
    end
  end

  context "changing application config" do
    it "fails" do
      response = http.get("http://localhost:#{port}/mutate/application/config")
      expect(response.body.to_s).to eq("frozen")
    end
  end

  context "defining an application aspect" do
    it "fails" do
      response = http.get("http://localhost:#{port}/mutate/application/aspect")
      expect(response.body.to_s).to eq("frozen")
    end
  end
end
