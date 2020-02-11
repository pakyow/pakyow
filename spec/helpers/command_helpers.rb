require "fileutils"

module CommandHelpers
  def command_dir
    File.expand_path("../../tmp", __FILE__)
  end

  def run_command(command, cleanup: true, project: false, **options)
    # Set the working directory to the supporting app.
    #
    original_pwd = Dir.pwd
    FileUtils.mkdir_p(command_dir)
    Dir.chdir(command_dir)

    output = StringIO.new
    allow(output).to receive(:tty?).and_return(true)
    allow(Pakyow::CLI).to receive(:project_context?).and_return(project)
    allow(Process).to receive(:exit)

    Pakyow.load_tasks
    Pakyow.load_commands
    Pakyow::CLI.new(feedback: Pakyow::CLI::Feedback.new(output)).call(command, **options)
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
