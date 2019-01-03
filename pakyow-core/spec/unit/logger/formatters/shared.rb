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

  let :prologue do
    {
      method: "GET",
      uri: "/",
      ip: "0.0.0.0",
      time: datetime
    }
  end

  let :epilogue do
    {
      status: 200
    }
  end

  let :error do
    ArgumentError.new("foo").tap do |error|
      error.set_backtrace(["one", "two"])
    end
  end
end
