require "fileutils"

module CommandHelpers
  def command_dir
    File.expand_path("../../tmp", __FILE__)
  end

  def run_command(*command, cleanup: true)
    # Set the working directory to the supporting app.
    #
    original_pwd = Dir.pwd
    FileUtils.mkdir_p(command_dir)
    Dir.chdir(command_dir)

    output = StringIO.new
    allow(output).to receive(:tty?).and_return(true)
    Pakyow::CLI.new(command, feedback: Pakyow::CLI::Feedback.new(output))
    yield if block_given?
    output.rewind
    output.read
  ensure
    # Set the working directory back to the original value.
    #
    Dir.chdir(original_pwd)

    if cleanup
      cleanup_after_command
    end
  end

  def cleanup_after_command
    FileUtils.rm_r(command_dir)
  end
end
