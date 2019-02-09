RSpec.describe "streaming responses" do
  before do
    Pakyow.action(&action)
  end

  include_context "app"

  let :action do
    Proc.new do |connection|
      connection.stream do
        100.times do |i|
          connection << i.to_s
        end
      end
    end
  end

  it "streams" do
    response = call("/", tuple: false)

    100.times do |i|
      expect(response.body.read).to eq(i.to_s)
    end

    expect(response.body.read).to be(nil)
  end

  context "non-blocking sleep during a stream" do
    let :action do
      Proc.new do |connection|
        connection.stream do |task|
          3.times do |i|
            connection.sleep(1)
            connection << Time.now.to_s
          end
        end
      end
    end

    before do
      Pakyow::Connection.before :finalize do
        write "finalize"
      end
    end

    after do
      Pakyow::Connection.__hook_hash[:before].clear
      Pakyow::Connection.__hook_pipeline[:before].clear
    end

    it "sleeps without blocking the connection from being finalized" do
      response = call("/", tuple: false)

      times = []
      while content = response.body.read
        times << content
      end

      expect(times.count).to eq(4)
      expect(times[0]).to eq("finalize")
      expect(times[1]).to eq((Time.now - 2).to_s)
      expect(times[2]).to eq((Time.now - 1).to_s)
      expect(times[3]).to eq((Time.now - 0).to_s)
    end
  end

  context "blocking during a stream" do
    let :action do
      Proc.new do |connection|
        connection.stream do |task|
          sleep(1)
          connection << "foo"
        end
      end
    end

    before do
      Pakyow::Connection.before :finalize do
        write "finalize"
      end
    end

    after do
      Pakyow::Connection.__hook_hash[:before].clear
      Pakyow::Connection.__hook_pipeline[:before].clear
    end

    it "blocks the connection from being finalized" do
      response = call("/", tuple: false)

      expect(response.body.read).to eq("foo")
      expect(response.body.read).to eq("finalize")
      expect(response.body.read).to be(nil)
    end
  end

  describe "streaming multiple times" do
    let :action do
      Proc.new do |connection|
        connection.stream do |task|
          connection.sleep(1)
          connection << "foo"
        end

        connection.stream do |task|
          connection << "bar"
        end
      end
    end

    it "streams from each" do
      response = call("/", tuple: false)

      expect(response.body.read).to eq("bar")
      expect(response.body.read).to eq("foo")
      expect(response.body.read).to be(nil)
    end
  end
end
