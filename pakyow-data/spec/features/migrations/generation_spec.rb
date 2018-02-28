require_relative "shared_examples/generating_migrations"

RSpec.describe "generating migrations in sqlite" do
  include_examples :generating_migrations
end

RSpec.describe "generating migrations in postgres" do
  include_examples :generating_migrations
end

RSpec.describe "generating migrations in mysql" do
  include_examples :generating_migrations
end
