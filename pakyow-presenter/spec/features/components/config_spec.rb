RSpec.describe "accessing component config from the backend" do
  include_context "app"

  let :app_def do
    Proc.new do
      component :configured do
        def perform
          $config = config
        end
      end
    end
  end

  after do
    $config = nil
  end

  it "exposes the component config" do
    call("/components/config")

    expect($config).to eq(
      foo: true, bar: "baz"
    )
  end

  context "multiple components are attached to a node" do
    let :app_def do
      Proc.new do
        component :configured1 do
          def perform
            $config[:configured1] = config
          end
        end

        component :configured2 do
          def perform
            $config[:configured2] = config
          end
        end
      end
    end

    before do
      $config = {}
    end

    it "exposes the config for each component" do
      call("/components/config-multiple")

      expect($config).to eq(
        configured1: {
          foo: true, bar: "baz"
        },

        configured2: {
          baz: "qux"
        }
      )
    end
  end
end
