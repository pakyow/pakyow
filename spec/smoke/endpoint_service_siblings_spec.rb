require "smoke_helper"

RSpec.describe "running sibling services alongside the endpoint service", :repeatable, smoke: true do
  before do
    File.open(project_path.join("config/environment.rb"), "w+") do |file|
      file.write <<~SOURCE
        Pakyow.class_state :queue, default: Queue.new

        Pakyow.after "setup" do
          container(:server).service(:reader, restartable: false) do
            def perform
              puts "!!! READER PERFORM"

              while (item = Pakyow.queue.pop)
                puts "!!! GOT item"

                File.open("#{output_path}", "a") do |file|
                  file.write(item)
                end
              end
            end
          end
        end
      SOURCE
    end

    File.open(project_path.join("config/application.rb"), "w+") do |file|
      file.write <<~SOURCE
        Pakyow.app :smoke_test, only: %i[routing] do
          controller "/" do
            default do
              Pakyow.queue.push(:called)
            end
          end
        end
      SOURCE
    end

    FileUtils.touch(output_path)

    boot
  end

  let(:output_path) {
    project_path.join("output.txt")
  }

  it "shares data between services" do
    response = http.get("http://localhost:#{port}")
    expect(response.status).to eq(200)

    sleep 2

    expect(output_path.read).to eq("calledcalled")
  end
end
