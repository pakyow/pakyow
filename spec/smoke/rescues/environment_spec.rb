require "smoke_helper"

RSpec.describe "rescuing the environment", smoke: true do
  context "error occurs before load" do
    before do
      File.open(project_path.join("config/environment.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.on :load do
            fail "something went wrong"
          end
        SOURCE
      end

      boot(wait: false)
    end

    it "fails to boot" do
      expect {
        HTTP.get("http://localhost:#{port}/")
      }.to raise_error(HTTP::ConnectionError)
    end
  end

  context "error occurs before setup" do
    before do
      File.open(project_path.join("config/environment.rb"), "w+") do |file|
        file.write <<~SOURCE
          Pakyow.on :setup do
            fail "something went wrong"
          end
        SOURCE
      end

      boot
    end

    it "responds 500" do
      response = HTTP.get("http://localhost:#{port}/")

      expect(response.status).to eq(500)
    end
  end
end
