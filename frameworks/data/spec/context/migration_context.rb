require "rake"

RSpec.shared_context "migration" do
  include_context "command"

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

    setup
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
    run_command("db:migrate", adapter: :sql, connection: :default, project: true)

    Pakyow.instance_variable_set(:@__loaded, false)
    Pakyow.instance_variable_set(:@__setup, false)
    Pakyow.instance_variable_set(:@__booted, false)
  end

  def finalize_migrations(count_before, count_after)
    verify_migration_count(count_before) do
      run_command("db:finalize", adapter: :sql, connection: :default, project: true)
    end

    Pakyow.instance_variable_set(:@__loaded, false)
    Pakyow.instance_variable_set(:@__setup, false)
    Pakyow.instance_variable_set(:@__booted, false)
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
