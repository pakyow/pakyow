require "smoke_helper"

RSpec.describe "booting a formation", smoke: true do
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

    boot(formation: "environment.server=1")
  end

  it "boots" do
    response = http.get("http://localhost:#{port}/")
    expect(response.body.to_s).to eq("foo")
  end
end
