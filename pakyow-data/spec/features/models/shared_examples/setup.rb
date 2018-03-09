RSpec.shared_examples :model_setup do
  describe "model setup" do
    before do
      Pakyow.config.data.connections.sql[:default] = connection_string
    end

    include_context "testable app"

    context "model defines a setup block" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          model :post do
            primary_id

            setup do
              $context = self
            end
          end
        end
      end

      after do
        $context = nil
      end

      it "evaluates it in context of ROM's schema dsl" do
        expect($context.class).to eq(ROM::SQL::Schema::DSL)
      end
    end
  end
end
