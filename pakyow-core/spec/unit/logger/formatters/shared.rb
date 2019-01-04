RSpec.shared_examples :log_formatter do
  let :severity do
    "DEBUG"
  end

  let :datetime do
    Time.now
  end

  let :progname do
    :rspec
  end

  let :connection do
    Pakyow::Connection.new(
      instance_double(Pakyow::App),
      Rack::REQUEST_METHOD => "GET",
      Rack::PATH_INFO => "/",
      "REMOTE_ADDR" => "0.0.0.0"
    )
  end

  let :error do
    ArgumentError.new("foo").tap do |error|
      error.set_backtrace(["one", "two"])
    end
  end
end
