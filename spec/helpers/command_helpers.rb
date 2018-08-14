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

    original_argv = ARGV.dup
    ARGV.clear
    ARGV.concat(command)

    output = capture_stdout do
      eval(File.read(File.expand_path("../../../pakyow-core/commands/pakyow", __FILE__)))
      yield if block_given?
    end

    ARGV.clear
    ARGV.concat(original_argv)

    # Set the working directory back to the original value.
    #
    Dir.chdir(original_pwd)

    if cleanup
      cleanup_after_command
    end

    output
  end

  def cleanup_after_command
    FileUtils.rm_r(command_dir)
  end
end
