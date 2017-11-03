RSpec.shared_context "suppressed output" do
  before do
    @original_stderr = $stderr.clone
    $stderr.reopen(File.new("/dev/null", "w"))
  end

  after do
    $stderr.reopen(@original_stderr)
  end
end
