RSpec.describe "handling errors in operations" do
  include_context "app"

  describe "handler for any error" do
    let :app_init do
      Proc.new do
        operation :test do
          attr_reader :handled

          handle do
            @handled = true
          end

          action :raise_error do
            raise RuntimeError
          end
        end
      end
    end

    it "handles the error" do
      Pakyow.app(:test).operations.test.tap do |operation|
        expect(operation.handled).to be(true)
      end
    end
  end

  describe "handler for a specific error" do
    context "specific error is raised" do
      let :app_init do
        Proc.new do
          operation :test do
            attr_reader :handled

            handle RuntimeError do
              @handled = true
            end

            action :raise_error do
              raise RuntimeError
            end
          end
        end
      end

      it "handles the error" do
        Pakyow.app(:test).operations.test.tap do |operation|
          expect(operation.handled).to be(true)
        end
      end
    end

    context "other error is raised" do
      let :app_init do
        Proc.new do
          operation :test do
            attr_reader :handled

            handle RuntimeError do
              @handled = true
            end

            action :raise_error do
              raise ArgumentError
            end
          end
        end
      end

      it "does not handle the error" do
        expect {
          Pakyow.app(:test).operations.test
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "unhandled errors" do
    let :app_init do
      Proc.new do
        operation :test do
          attr_reader :handled

          action :raise_error do
            raise RuntimeError
          end
        end
      end
    end

    it "re-raises" do
      expect {
        Pakyow.app(:test).operations.test
      }.to raise_error(RuntimeError)
    end
  end
end
