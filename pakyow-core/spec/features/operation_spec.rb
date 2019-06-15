RSpec.describe "operation" do
  include_context "app"

  let :action do
    local = self
    Class.new do
      include Pakyow::Helpers::Connection
      instance_variable_set(:@local, local)
      def call(connection)
        @connection = connection

        self.class.instance_variable_get(:@local).instance_variable_set(
          :@result, operations.test(foo: "foo", bar: "bar")
        )

        connection.halt
      end
    end
  end

  let :app_def do
    local = self
    Proc.new do
      operation :test do
        attr_reader :foo_result, :bar_result, :baz_result

        action :foo do
          @foo_result = @values[:foo].reverse
        end

        action :bar do
          @bar_result = @values[:bar].reverse
        end
      end

      action local.action
    end
  end

  it "can be called with values" do
    expect(call("/")[0]).to eq(200)
    expect(@result.foo_result).to eq("oof")
    expect(@result.bar_result).to eq("rab")
  end

  it "has access to the app" do
    expect(call("/")[0]).to eq(200)
    expect(@result.app).to be_instance_of(Test::App)
  end

  it "has access to values" do
    expect(call("/")[0]).to eq(200)
    expect(@result.values).to eq(foo: "foo", bar: "bar")
  end

  describe "modifying the operation at runtime" do
    let :action do
      local = self
      Class.new do
        include Pakyow::Helpers::Connection
        instance_variable_set(:@local, local)
        def call(connection)
          @connection = connection

          result = if connection.params[:modified]
            operations.test(foo: "foo", bar: "bar", baz: "baz") do
              action :baz do
                @baz_result = @values[:baz].reverse
              end
            end
          else
            operations.test(foo: "foo", bar: "bar", baz: "baz")
          end

          self.class.instance_variable_get(:@local).instance_variable_set(
            :@result, result
          )

          connection.halt
        end
      end
    end

    it "modifies the operation" do
      expect(call("/?modified=true")[0]).to eq(200)
      expect(@result.foo_result).to eq("oof")
      expect(@result.bar_result).to eq("rab")
      expect(@result.baz_result).to eq("zab")
    end

    it "does not modify future calls" do
      expect(call("/")[0]).to eq(200)
      expect(@result.foo_result).to eq("oof")
      expect(@result.bar_result).to eq("rab")
      expect(@result.baz_result).to eq(nil)
    end
  end
end
