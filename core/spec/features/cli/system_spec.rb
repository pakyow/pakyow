require "fileutils"

require "pakyow/cli"

RSpec.describe "calling a system command through the cli" do
  after do
    FileUtils.rm_f("./touched.txt")
  end

  it "calls the command" do
    capture_output do
      Pakyow::CLI.system("touch", "./touched.txt")
    end

    expect(File.exist?("./touched.txt")).to be(true)
  end

  it "returns the result" do
    result = nil

    capture_output do
      result = Pakyow::CLI.system("touch", "./touched.txt")
    end

    expect(result).to be_instance_of(Pakyow::CLI::System::Result)
    expect(result.complete?).to be(true)
    expect(result.success?).to be(true)
  end

  context "command fails" do
    it "returns an unsuccessful result" do
      result = nil

      capture_output do
        result = Pakyow::CLI.system("ls nonexistent")
      end

      expect(result.complete?).to be(true)
      expect(result.success?).to be(false)
      expect(result.failure?).to be(true)
    end
  end

  describe "output" do
    it "logs correctly" do
      output = capture_output do
        Pakyow::CLI.system("touch", "./touched.txt")
      end

      expect(output).to include("cmd.")
      expect(output).to end_with(" | running: touch ./touched.txt\e[0m\n")
    end

    context "logger key is passed" do
      it "logs correctly" do
        output = capture_output do
          Pakyow::CLI.system("touch", "./touched.txt", logger_key: "touch")
        end

        expect(output).to include("touch.")
        expect(output).to end_with(" | running: touch ./touched.txt\e[0m\n")
      end
    end
  end
end
