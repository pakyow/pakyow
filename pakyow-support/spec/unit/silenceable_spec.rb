RSpec.describe Pakyow::Support::Silenceable do
  let :instance do
    Class.new {
      include Pakyow::Support::Silenceable
    }.new
  end

  it "silences warnings" do
    @verbosity = true
    Pakyow::Support::Silenceable.silence_warnings {
      @verbosity = $VERBOSE
    }

    expect(@verbosity).to be_nil
  end

  it "sets verbosity back to the original value" do
    Pakyow::Support::Silenceable.silence_warnings {}
    expect($VERBOSE).to eq(true)
  end

  it "sets verbosity back to the original value on failure" do
    begin
      Pakyow::Support::Silenceable.silence_warnings { fail }
    rescue
    end

    expect($VERBOSE).to eq(true)
  end

  it "silences within an instance" do
    @verbosity = true
    instance.silence_warnings {
      @verbosity = $VERBOSE
    }

    expect(@verbosity).to be_nil
  end
end
