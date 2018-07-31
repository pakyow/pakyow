namespace :test do
  describe "Test passing the environment"
  task :pass_env do
    puts "Pakyow.env: #{Pakyow.env}"
  end

  describe "Test passing the application"
  task :pass_app, [:app] do |_, args|
    puts "args[:app]: #{args[:app].config.name} (#{Pakyow.env})"
  end

  describe "Test arguments + options"
  argument :foo, "Foo arg", required: true
  argument :bar, "Bar arg"
  option :baz, "Baz arg", required: true
  option :qux, "Qux arg"
  flag :meh, "Meh flag"
  task :pass_arg_opt_flg, [:foo, :bar, :baz, :qux, :meh] do |_, args|
  end
end
