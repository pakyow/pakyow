RSpec.describe "environment dispatch hooks" do
  include_context "app"

  let(:env_def) {
    local = self

    Proc.new {
      before :dispatch do |*args, **kwargs|
        local.calls[:before] << [args, kwargs]
      end

      after :dispatch do |*args, **kwargs|
        local.calls[:after] << [args, kwargs]
      end
    }
  }

  before do
    @calls = { before: [], after: [] }

    call("/")
  end

  after do
    @calls.clear
  end

  attr_reader :calls

  it "calls before dispatch hooks" do
    expect(@calls[:before]).not_to be_empty
  end

  it "passes the connection to before dispatch hooks" do
    expect(@calls[:before][0][1][:connection]).to be_instance_of(Pakyow::Connection)
  end

  it "calls after dispatch hooks" do
    expect(@calls[:after]).not_to be_empty
  end

  it "passes the connection to after dispatch hooks" do
    expect(@calls[:after][0][1][:connection]).to be_instance_of(Pakyow::Connection)
  end
end
