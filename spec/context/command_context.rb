require "tty-spinner"

RSpec.shared_context "command" do
  before do
    allow_any_instance_of(TTY::Spinner).to receive(:auto_spin)
    allow_any_instance_of(TTY::Spinner).to receive(:success)
    expect(::Process).not_to receive(:exit)
  end
end
