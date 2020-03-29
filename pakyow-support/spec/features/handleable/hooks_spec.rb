RSpec.describe "calling hooks when handling an event" do
  let(:handleable) {
    Class.new do
      include Pakyow::Support::Hookable
      include Pakyow::Support::Handleable
    end
  }

  attr_accessor :calls

  before do
    local = self

    handleable.handle :foo do; end

    handleable.before :handle do |event, *args, **kwargs|
      local.calls[:before] << [event, args, kwargs]
    end

    handleable.after :handle do |event, *args, **kwargs|
      local.calls[:after] << [event, args, kwargs]
    end

    @calls = { before: [], after: [] }
  end

  after do
    @calls.clear
  end

  it "calls before hooks" do
    handleable.trigger :foo

    expect(@calls[:before]).not_to be_empty
  end

  it "calls after hooks" do
    handleable.trigger :foo

    expect(@calls[:after]).not_to be_empty
  end

  it "passes the event to before hooks" do
    handleable.trigger :foo

    expect(@calls[:before][0][0]).to eq(:foo)
  end

  it "passes the event to after hooks" do
    handleable.trigger :foo

    expect(@calls[:after][0][0]).to eq(:foo)
  end

  context "arguments are passed when triggering" do
    before do
      handleable.trigger :foo, :arg
    end

    it "passes the arguments to the hooks" do
      expect(@calls[:before][0][1]).to eq([:arg])
      expect(@calls[:after][0][1]).to eq([:arg])
    end
  end

  context "keyword arguments are passed when triggering" do
    before do
      handleable.trigger :foo, key: :value
    end

    it "passes the keyword arguments to the hooks" do
      expect(@calls[:before][0][2]).to eq({ key: :value })
      expect(@calls[:after][0][2]).to eq({ key: :value })
    end
  end
end
