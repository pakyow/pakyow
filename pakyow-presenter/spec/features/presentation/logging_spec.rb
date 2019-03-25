RSpec.describe "logging within a presenter" do
  include_context "app"

  let :app_init do
    local = self
    Proc.new do
      presenter "/presentation/attached_renders" do
        render :post do
          local.instance_variable_set(:@logger, logger)
        end
      end
    end
  end

  it "exposes the connection logger" do
    expect(call("/presentation/attached_renders")[0]).to eq(200)
    expect(@logger).to be_instance_of(Pakyow::Logger::ThreadLocal)
  end
end
