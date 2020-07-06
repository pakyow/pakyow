require "smoke_helper"

RSpec.describe "setting the content length header on the response", smoke: true do
  before do
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

    boot
  end

  it "is set" do
    response = http.get("http://localhost:#{port}/")
    expect(response.headers["Content-Length"].to_i).to eq(3)
  end

  context "request is head" do
    it "is set" do
      response = http.head("http://localhost:#{port}/")
      expect(response.headers["Content-Length"].to_i).to eq(3)
    end
  end
end
