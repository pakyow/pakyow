require "smoke_helper"

RSpec.describe "signaling a running project", smoke: true do
  context "INT" do
    before do
      boot do
        shutdown("INT")
      end
    end

    it "shuts down" do
      expect {
        HTTP.head("http://localhost:#{port}/")
      }.to raise_error(HTTP::ConnectionError)
    end

    it "invokes the shutdown sequence" do
      expect(Dir.glob(project_path.join("tmp/state/**/*"))).to include(project_path.join("tmp/state/smoke_test-subscribers.pwstate").to_s)
      expect(Dir.glob(project_path.join("tmp/state/**/*"))).to include(project_path.join("tmp/state/smoke_test-realtime.pwstate").to_s)
    end
  end

  context "TERM" do
    before do
      boot do
        shutdown("TERM")
      end
    end

    it "shuts down" do
      expect {
        HTTP.head("http://localhost:#{port}/")
      }.to raise_error(HTTP::ConnectionError)
    end

    it "does not invoke the shutdown sequence" do
      expect(Dir.glob(project_path.join("tmp/state/**/*"))).not_to include(project_path.join("tmp/state/smoke_test-subscribers.pwstate").to_s)
      expect(Dir.glob(project_path.join("tmp/state/**/*"))).not_to include(project_path.join("tmp/state/smoke_test-realtime.pwstate").to_s)
    end
  end

  context "HUP" do
    before do
      boot do
        File.open(project_path.join("config/application.rb"), "w+") do |file|
          file.write <<~SOURCE
            Pakyow.app :smoke_test, only: %i[routing data] do
              controller "/" do
                default do
                  send "foo"
                end
              end
            end
          SOURCE
        end
      end

      shutdown("HUP")
    end

    it "reloads" do
      response = HTTP.get("http://localhost:#{port}/")
      expect(response.body.to_s).to eq("foo")
    end
  end
end
