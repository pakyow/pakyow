RSpec.describe Pakyow::Application, "#handle" do
  let(:instance) {
    described_class.new
  }

  it "is not defined" do
    expect {
      instance.handle
    }.to raise_error(NoMethodError)
  end
end
