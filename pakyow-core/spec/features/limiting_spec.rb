RSpec.describe "limiting the connection input size" do
  include_context "app"

  let(:env_def) {
    Proc.new {
      configure do
        config.limiter.length = 1024
      end

      action do |connection|
        connection.body = connection.params[:value]
        connection.halt
      end
    }
  }

  let(:response) {
    call(params: params)
  }

  context "input equals the limit" do
    let(:params) {
      { value: " " * 1012 }
    }

    it "allows the input" do
      expect(response[0]).to eq(200)
      expect(response[2]).to eq(params[:value])
    end
  end

  context "input is over the limit" do
    let(:params) {
      { value: " " * 1013 }
    }

    it "responds 413" do
      expect(response[0]).to eq(413)
      expect(response[2]).to eq("413 Payload Too Large")
    end

    describe "raised error" do
      let(:env_def) {
        super_def = super()

        Proc.new {
          instance_eval(&super_def)

          handle Pakyow::RequestTooLarge do |error, connection:|
            connection.body = error.message
            connection.halt
          end
        }
      }

      it "raises a RequestTooLarge error" do
        expect(response[0]).to eq(200)
        expect(response[2]).to eq("Request length `1025' exceeds the defined limit of `1024'")
      end
    end
  end
end
