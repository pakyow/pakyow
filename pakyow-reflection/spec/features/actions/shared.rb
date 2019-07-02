RSpec.shared_context "resource action" do
  include_context "reflectable app"

  let :data do
    Pakyow.apps.first.data
  end

  let :values do
    {}
  end

  let :path do
    "/"
  end

  let :method do
    :post
  end

  let :params do
    values.merge(
      authenticity_token: authenticity_token,
      _form: sign(form)
    )
  end

  let :form do
    {
      view_path: "/",
      binding: "post:form",
      origin: "/"
    }
  end

  let :response do
    call(
      path,
      method: method,
      params: params,
      headers: {
        "cookie" => cookie,
        "origin" => "http://localhost"
      }
    )
  end

  let :authenticity_call do
    call("/authenticity")
  end

  let :authenticity_token do
    authenticity_call[2]
  end

  let :cookie do
    authenticity_call[1]["set-cookie"].to_s
  end

  def sign(value)
    Pakyow::Support::MessageVerifier.new.sign(value.to_json)
  end

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("key")
  end
end
