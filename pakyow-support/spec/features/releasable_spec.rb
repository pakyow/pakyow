require "pakyow/support/class_state"
require "pakyow/support/releasable"

RSpec.describe "releasable" do
  let(:subject) {
    Class.new do
      extend Pakyow::Support::ClassState
      class_state :released, default: []

      include Pakyow::Support::Releasable
    end
  }

  it "can define a release channel with a risk" do
    expect {
      subject.release_channel :foo, risk: 10
    }.not_to raise_error
  end

  it "returns a list of known release channels" do
    subject.release_channel :foo, risk: 10
    subject.release_channel :bar, risk: 5

    expect(subject.release_channels).to eq([:default, :foo, :bar])
  end

  it "knows that a release channel is defined" do
    subject.release_channel :foo, risk: 10

    expect(subject.release_channel?(:foo)).to be(true)
  end

  it "knows that a release channel is not defined" do
    expect(subject.release_channel?(:foo)).to be(false)
  end

  it "sets the current release channel" do
    subject.release_channel :foo, risk: 10

    expect {
      subject.release_channel = :foo
    }.not_to raise_error
  end

  it "errors when setting to an unknown release channel" do
    expect {
      subject.release_channel = :foo
    }.to raise_error(Pakyow::Support::Releasable::UnknownReleaseChannel, "unknown release channel `foo'")
  end

  describe "releasing code" do
    before do
      subject.release_channel :danger, risk: 30
      subject.release_channel :alpha, risk: 20
      subject.release_channel :beta, risk: 10

      subject.releasable :alpha do
        self.released << :alpha
      end

      subject.releasable :beta do
        self.released << :beta
      end

      subject.releasable :danger do
        self.released << :danger
      end

      subject.release_channel = :alpha
    end

    it "releases code that matches the current risk" do
      expect(subject.released).to include(:alpha)
    end

    it "releases code that is less than the current risk" do
      expect(subject.released).to include(:beta)
    end

    it "does not release code that is higher than the current risk" do
      expect(subject.released).not_to include(:danger)
    end

    it "releases code immediately after setting the release channel" do
      subject.releasable :beta do
        self.released << :beta2
      end

      expect(subject.released).to include(:beta2)
    end
  end
end
