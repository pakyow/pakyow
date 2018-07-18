module OutputHelpers
  def capture_output(capture = StringIO.new)
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = capture
    $stderr = capture
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  def capture_stdout(capture = StringIO.new)
    original_stdout = $stdout
    $stdout = capture
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def capture_stderr(capture = StringIO.new)
    original_stderr = $stderr
    $stderr = capture
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end
end
