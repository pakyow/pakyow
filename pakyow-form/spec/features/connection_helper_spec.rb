RSpec.describe "form connection helper" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :posts, "/posts" do
        disable_protection :csrf

        new do; end

        create do
          $form = connection.form
        end
      end
    end
  end

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("key")
  end

  def sign(metadata)
    Pakyow::Support::MessageVerifier.new.sign(metadata.to_json)
  end

  it "exposes the submitted form" do
    expect(call("/posts", method: :post, params: { :"pw-form" => sign(origin: "/posts/new") })[0]).to be(200)
    expect($form).to eq(origin: "/posts/new")
  end
end
