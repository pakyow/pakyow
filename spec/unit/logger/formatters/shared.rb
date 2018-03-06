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
      prologue: {
        method: "GET",
        uri: "/",
        ip: "0.0.0.0",
        time: datetime,
      }
    }.merge(message)
  end

  let :epilogue do
    {
      epilogue: {
        status: 200
      }
    }.merge(message)
  end

  let :error do
    error = ArgumentError.new("foo")
    error.set_backtrace(["one", "two"])
    { error: error }.merge(message)
  end

  let :message do
    {
      elapsed: 0.01,
      request: {
        id: "123",
        type: "http",
      },
      message: "foo",
    }
  end
end
