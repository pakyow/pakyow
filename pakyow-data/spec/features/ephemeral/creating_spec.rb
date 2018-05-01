RSpec.describe "creating an ephemeral data source" do
  include_context "testable app"

  let :app_definition do
    Proc.new do
      instance_exec(&$data_app_boilerplate)

      controller do
        get "ephemeral" do
          $data = data.ephemeral(:test)
        end

        get "ephemeral-with-id/:id" do
          $data = data.ephemeral(:test, id: params[:id])
        end

        get "ephemeral-with-value/:value" do
          $data = data.ephemeral(:test).set(params[:value])
        end
      end
    end
  end

  after do
    $data = nil
  end

  it "creates an ephemeral data object wrapped in a proxy" do
    expect(call("/ephemeral")[0]).to eq(200)
    expect($data).to be_instance_of(Pakyow::Data::Proxy)
    expect($data.source).to be_instance_of(Pakyow::Data::Sources::Ephemeral)
  end

  it "can be created with a type" do
    expect(call("/ephemeral")[0]).to eq(200)
    expect($data.source.type).to eq(:test)
  end

  it "is given a uuid" do
    expect(call("/ephemeral")[0]).to eq(200)
    expect($data.source.id.length).to eq(36)
  end

  it "can be created with an explicit id" do
    expect(call("/ephemeral-with-id/123")[0]).to eq(200)
    expect($data.source.id).to eq("123")
  end

  it "can have a value set on it" do
    expect(call("/ephemeral-with-value/foo")[0]).to eq(200)
    expect($data.value).to eq("foo")
  end
end
