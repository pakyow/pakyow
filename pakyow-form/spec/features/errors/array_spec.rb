RSpec.describe "triggering errors with a result containing an array of messages" do
  include_context "app"

  let :app_def do
    local_result_class = result_class

    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        new do; end

        create do
          error = Pakyow::InvalidData.new

          error.context = {
            object: {}, result: local_result_class.new(
              messages: [
                "something went wrong",
                "something else went wrong"
              ]
            )
          }

          raise error
        end
      end
    end
  end

  let :result_class do
    Class.new do
      attr_reader :messages

      def initialize(messages: [])
        @messages = messages
      end
    end
  end

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("key")
  end

  def sign(metadata)
    Pakyow::Support::MessageVerifier.new.sign(metadata.to_json)
  end

  it "presents errors for the invalid submission" do
    call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new", binding: "post:form") }).tap do |result|
      expect(result[0]).to be(400)
      body = result[2]
      expect(body).to include_sans_whitespace("something went wrong")
      expect(body).to include_sans_whitespace("something elsewent wrong")
    end
  end
end
