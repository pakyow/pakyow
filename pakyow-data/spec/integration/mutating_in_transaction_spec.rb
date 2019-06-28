RSpec.describe "mutating in a transaction" do
  before do
    Pakyow.after "configure" do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      source :posts do
        attribute :title, :string
      end
    end
  end

  it "does not call did_mutate until the transaction is committed" do
    expect(Pakyow.app(:test).data.subscribers).to receive(:did_mutate) do
      expect(Pakyow.app(:test).data.posts.transaction?).to be(false)
    end

    Pakyow.app(:test).data.posts.transaction do
      Pakyow.app(:test).data.posts.create(title: "foo")
    end
  end
end
