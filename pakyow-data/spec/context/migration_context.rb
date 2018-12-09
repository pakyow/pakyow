RSpec.shared_context "migration" do
  before do
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

  def run_migrations
    Rake::Task["db:migrate"].reenable
    Rake::Task["db:migrate"].invoke("sql", "default")

    # Invalidate the schema cache.
    #
    Pakyow.data_connections[:sql][:default].adapter.connection.tables
  end

  def finalize_migrations(count_before, count_after)
    verify_migration_count(count_before) do
      Rake::Task["db:finalize"].reenable
      Rake::Task["db:finalize"].invoke("sql", "default")
      verify_migration_count(count_after)
    end

    # Invalidate the schema cache.
    #
    Pakyow.data_connections[:sql][:default].adapter.connection.tables
  end

  private

  def verify_migration_count(count)
    if migrations.count < count
      fail "Expected #{count} migrations, but only found #{migrations.count}"
    elsif migrations.count > count
      extra_count = migrations.count - count
      message = "Found #{extra_count} migrations more than expected:\n"
      migrations.reverse.take(extra_count).reverse.each do |migration|
        message << "\n# #{File.basename(migration)}\n"
        message << File.read(migration)
      end
      fail message
    else
      yield if block_given?
    end
  end
end
