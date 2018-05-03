RSpec.shared_context "migration" do
  before do
    Pakyow.config.data.connections.sql[:default] = "sqlite::memory"
    Pakyow.config.data.migration_path = migration_path

    # Create the initial migrations.
    #
    FileUtils.mkdir_p(adapter_migration_path)

    initial_migration_content.each do |filename, content|
      File.open(File.join(adapter_migration_path, filename), "w+") do |file|
        file.write(content)
      end
    end
  end

  after do
    FileUtils.rm_r(File.expand_path("../support", __FILE__))
  end

  let :migration_path do
    File.expand_path("../support/database/migrations", __FILE__)
  end

  def adapter_migration_path
    File.join(Pakyow.config.data.migration_path, "sql", "default")
  end

  def migrations
    Dir.glob(File.join(adapter_migration_path, "*.rb")).sort
  end
end
