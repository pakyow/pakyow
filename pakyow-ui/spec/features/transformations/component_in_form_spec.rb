RSpec.describe "presenting data in a form component" do
  include_context "testable app"
  include_context "websocket intercept"

  let :app_definition do
    Proc.new do
      instance_exec(&$ui_app_boilerplate)

      resource :posts, "/posts" do
        disable_protection :csrf

        create do
          data.ephemeral(:error, form_id: "form_1").set([{ id: 1, message: "error 1" }, { id: 2, message: "error 2" }]); halt
        end
      end

      source :posts do
        primary_id
        attribute :title
      end

      component :errors do
        def perform
          expose :errors, data.ephemeral(:error, form_id: "form_1")
        end

        presenter do
          def perform
            # This is weird, but done so the ephemeral data shows up in the result.
            #
            presenting = if $call_count == 1
              [{ id: 1, message: "error 1" }, { id: 2, message: "error 2" }]
            else
              errors
            end

            find(:error).present(presenting)
            $call_count += 1
          end
        end
      end
    end
  end

  before do
    $call_count = 0
  end

  after do
    $call_count = nil
  end

  it "transforms" do |x|
    save_ui_case(x, path: "/component-in-form/posts") do
      call("/posts", method: :post)
    end
  end
end
