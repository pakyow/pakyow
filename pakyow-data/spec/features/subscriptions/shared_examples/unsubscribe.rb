RSpec.shared_examples :subscription_unsubscribe do
  it "needs to be defined"

  # class TestHandler
  #   def initialize(app)
  #     @app = app
  #   end

  #   def call(args, result: nil, subscription: nil)
  #   end
  # end

  # include_context "testable app"

  # let :app_definition do
  #   Pakyow.config.data.connections.memory[:default] = "memory://test"
  #   Pakyow.config.data.subscriptions.adapter = data_subscription_adapter

  #   Proc.new do
  #     source :post do
  #       attribute :title, :string

  #       def with_title(title)
  #         restrict(title: title)
  #       end
  #     end

  #     source :comment do
  #       attribute :title, :string

  #       def with_title(title)
  #         restrict(title: title)
  #       end
  #     end

  #     resource :posts, "/posts" do
  #       skip_action :verify_same_origin
  #       skip_action :verify_authenticity_token

  #       create do
  #         verify do
  #           required :post do
  #             required :title
  #           end
  #         end

  #         data.posts.create(params[:post])
  #       end

  #       update do
  #         verify do
  #           required :post do
  #             required :title
  #           end
  #         end

  #         data.posts.with_title(params[:post_id]).update(params[:post])
  #       end

  #       delete do
  #         data.posts.with_title(params[:post_id]).delete
  #       end

  #       collection do
  #         post "subscribe" do
  #           data.posts.subscribe(:post_subscriber, handler: TestHandler)
  #         end

  #         post "unsubscribe" do
  #           data.subscribers.unsubscribe(:post_subscriber)
  #         end
  #       end
  #     end

  #     resource :comments, "/comments" do
  #       skip_action :verify_same_origin
  #       skip_action :verify_authenticity_token

  #       create do
  #         verify do
  #           required :comment do
  #             required :title
  #           end
  #         end

  #         data.comments.create(params[:comment])
  #       end

  #       update do
  #         verify do
  #           required :comment do
  #             required :title
  #           end
  #         end

  #         data.comments.with_title(params[:comment_id]).update(params[:comment])
  #       end

  #       delete do
  #         data.comments.with_title(params[:comment_id]).delete
  #       end
  #     end
  #   end
  # end

  # def subscribe!
  #   response = call("/posts/subscribe", method: :post)
  #   expect(response[0]).to eq(200)
  # end

  # def unsubscribe!
  #   response = call("/posts/unsubscribe", method: :post)
  #   expect(response[0]).to eq(200)
  # end

  # after do
  #   unsubscribe!
  # end

  # describe "unsubscribing from a query" do
  #   # TODO
  # end
end
