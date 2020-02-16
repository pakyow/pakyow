Pakyow.command :test, :pass_env do
  describe "Test passing the environment"
  required :cli

  action do
    cli.feedback.puts "Pakyow.env: #{Pakyow.env}"
  end
end

Pakyow.command :test, :pass_app do
  describe "Test passing the application"
  required :app
  required :cli

  action do
    cli.feedback.puts "args[:app]: #{app.config.name} (#{Pakyow.env})"
  end
end

Pakyow.command :test, :pass_arg_opt_flg do
  describe "Test arguments + options"
  argument :foo, "Foo arg", required: true
  argument :bar, "Bar arg"
  option :baz, "Baz arg", required: true
  option :qux, "Qux arg", default: "qux"
  flag :meh, "Meh flag"
end
