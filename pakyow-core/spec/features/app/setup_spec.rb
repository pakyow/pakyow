RSpec.describe "setting up an application" do
  include_context "app"

  context "app defines a before setup hook" do
    let(:app_def) {
      Proc.new {
        class << self
          attr_reader :called
        end

        on "setup" do
          @called = true
        end
      }
    }

    it "is called" do
      expect(Pakyow.app(:test).class.called).to be(true)
    end
  end
end
