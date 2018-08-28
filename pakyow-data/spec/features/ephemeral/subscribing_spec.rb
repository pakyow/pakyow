RSpec.describe "creating an ephemeral data source" do
  class TestHandler
    def initialize(app)
      @app = app
    end

    def call(*); end
  end

  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$data_app_boilerplate)

      resources :posts, "/posts" do
        disable_protection :csrf

        show do
          data.ephemeral(:errors, id: params[:id]).set([]).subscribe(:errors_subscriber, handler: TestHandler)
        end

        create do
          data.ephemeral(:errors, id: params[:id]).set([:error1, :error2, :error3])
        end
      end

      resources :comments, "/comments" do
        disable_protection :csrf

        create do
          data.ephemeral(:errors_for_comments, id: params[:id]).set([:error1, :error2, :error3])
        end
      end
    end
  end

  let :subscribers do
    Pakyow.apps.first.data.subscribers
  end

  before do
    allow_any_instance_of(Concurrent::ThreadPoolExecutor).to receive(:<<) do |_, block|
      block.call
    end
  end

  after do
    subscribers.unsubscribe(:errors_subscriber)
  end

  it "creates a subscriber for the ephemeral data object" do
    expect(call("/posts/1")[0]).to eq(200)
    expect(subscribers.instance_variable_get(:@adapter).subscriptions_for_source(:errors).count).to eq(1)
  end

  context "ephemeral source is changed in a separate call" do
    context "changed source is subscribed" do
      it "calls the handler" do
        expect(call("/posts/1")[0]).to eq(200)
        expect_any_instance_of(TestHandler).to receive(:call)
        expect(call("/posts", method: :post, params: { id: 1 })[0]).to eq(200)
      end
    end

    context "changed source does not match subscribed id" do
      it "does not call the handler" do
        expect(call("/posts/1")[0]).to eq(200)
        expect_any_instance_of(TestHandler).not_to receive(:call)
        expect(call("/posts", method: :post, params: { id: 2 })[0]).to eq(200)
      end
    end

    context "changed source does not match subscribed type" do
      it "does not call the handler" do
        expect(call("/posts/1")[0]).to eq(200)
        expect_any_instance_of(TestHandler).not_to receive(:call)
        expect(call("/comments", method: :post, params: { id: 1 })[0]).to eq(200)
      end
    end
  end
end
