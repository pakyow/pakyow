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
      binding: "post:form"
    }
  end

  let :response do
    call(
      path,
      method: method,
      params: params,
      "HTTP_COOKIE" => cookie,
      "HTTP_ORIGIN" => "http://example.org"
    )
  end

  let :authenticity_call do
    call("/authenticity")
  end

  let :authenticity_token do
    authenticity_call[2].body.read
  end

  let :cookie do
    authenticity_call[1]["Set-Cookie"]
  end

  def sign(value)
    Pakyow::Support::MessageVerifier.new.sign(value.to_json)
  end

  before do
    allow(Pakyow::Support::MessageVerifier).to receive(:key).and_return("key")
  end
end
