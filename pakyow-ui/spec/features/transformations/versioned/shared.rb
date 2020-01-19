RSpec.shared_context "versioned" do
  include_context "app"
  include_context "websocket intercept"

  let :app_def do
    local_presenter = presenter
    local_view_path = view_path

    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        list do
          expose :posts, data.posts
          render local_view_path
        end

        create do
          verify do
            required :post do
              required :title
            end
          end

          data.posts.create(params[:post]); halt
        end

        update do
          verify do
            required :id
            required :post do
              optional :published
              optional :title
            end
          end

          data.posts.by_id(params[:id]).update(params[:post])
        end
      end

      source :posts, timestamps: false do
        primary_id
        attribute :title
        attribute :published, :boolean, default: false
      end

      instance_exec(&local_presenter)
    end
  end
end
