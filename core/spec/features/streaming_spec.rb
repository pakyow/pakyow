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
            connection.sleep(0.01)
            connection << Time.now.to_f
          end
        end
      end
    end

    before do
      Pakyow::Connection.before "finalize" do
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
      expect(times[2]).to be_within(0.01).of(times[1] + 0.01)
      expect(times[3]).to be_within(0.01).of(times[2] + 0.01)
    end
  end

  describe "streaming multiple times" do
    let :action do
      Proc.new do |connection|
        connection.stream do |task|
          connection.sleep(0.01)
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
