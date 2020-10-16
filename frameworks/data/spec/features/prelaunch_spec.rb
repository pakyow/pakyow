RSpec.describe "data prelaunch commands" do
  before do
    Pakyow.configure do
      Pakyow.config.data.connections.sql[:default] = ENV["DATABASE_URL__POSTGRES"]
      Pakyow.config.data.connections.sql[:another] = ENV["DATABASE_URL__MYSQL"]
      Pakyow.config.data.connections.sql[:memory] = "sqlite::memory"
    end
  end

  include_context "app"

  describe "db:migrate" do
    it "is a prelaunch command" do
      expect(Pakyow.command(:db, :migrate).prelaunch?).to be(true)
    end

    it "is part of the release phase" do
      expect(Pakyow.command(:db, :migrate).prelaunch_phase).to eq(:release)
    end

    it "yields each migratable connection" do
      prelaunches = []

      Pakyow.command(:db, :migrate).prelaunches do |**args|
        prelaunches << args
      end

      expect(prelaunches).to eq([
        { adapter: :sql, connection: :default },
        { adapter: :sql, connection: :another }
      ])
    end
  end
end
