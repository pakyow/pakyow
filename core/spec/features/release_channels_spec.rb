RSpec.describe "using release channels" do
  include_context "app"

  let(:env_def) {
    local = self

    Proc.new {
      after "configure" do
        releasable :alpha do
          local.released << :alpha
        end

        releasable :beta do
          local.released << :beta
        end

        local.released << :default
      end
    }
  }

  let(:released) {
    []
  }

  it "respects the default release channel" do
    expect(released).to eq([:default])
  end

  context "release channel is set explicitly" do
    let(:env_def) {
      super_env_def = super()

      Proc.new {
        config.channel = :beta

        instance_eval(&super_env_def)
      }
    }

    it "respects the configured release channel" do
      expect(released).to eq([:beta, :default])
    end
  end
end
