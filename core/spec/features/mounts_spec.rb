RSpec.describe "mounting specific applications" do
  include_context "app"

  let(:env_def) {
    local = self

    Proc.new {
      app :test_foo do
        on :load do
          local.loaded << :foo
        end
      end

      app :test_bar do
        on :load do
          local.loaded << :bar
        end
      end

      app :test_baz do
        on :load do
          local.loaded << :baz
        end
      end
    }
  }

  let(:loaded) {
    []
  }

  let(:mount_app) {
    false
  }

  it "mounts all applications by default" do
    expect(loaded).to eq(%i(foo bar baz))
  end

  context "mounts describes a single application" do
    let(:env_def) {
      Pakyow.config.mounts = %i(test_foo)

      super()
    }

    it "mounts only the described application" do
      expect(loaded).to eq(%i(foo))
    end
  end

  context "mounts describes multiple applications" do
    let(:env_def) {
      Pakyow.config.mounts = %i(test_foo test_baz)

      super()
    }

    it "mounts all described applications" do
      expect(loaded).to eq(%i(foo baz))
    end
  end
end
