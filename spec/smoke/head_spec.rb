require "smoke_helper"

RSpec.describe "head requests", smoke: true do
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

  it "sets an empty body" do
    response = http.head("http://localhost:#{port}/")
    expect(response.body.to_s).to be_empty
  end

  it "sets the content-length header" do
    response = http.head("http://localhost:#{port}/")
    expect(response.headers["Content-Length"].to_i).to eq(3)
  end
end
