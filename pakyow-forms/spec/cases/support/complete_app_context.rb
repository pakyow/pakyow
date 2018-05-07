RSpec.shared_context "complete app" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      config.presenter.path = File.join(File.expand_path("../", __FILE__), "frontend")

      resources :posts, "/posts" do
        new do
          # intentionally empty
        end

        create do
          verify do
            required :post do
              required :title
            end
          end

          send "success"
        end
      end
    }
  end
end
