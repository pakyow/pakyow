RSpec.describe Pakyow::Presenter::UnknownPage do
  let :error do
    error = described_class.new
    error.context = context
    error
  end

  context "context is a path" do
    let :context do
      "/foo"
    end

    it "formats the message properly" do
      expect(error.contextual_message).to eq_sans_whitespace(
        <<~ERROR
          Pakyow couldn't render a view for `/foo`. Try creating a view template for this path:

              frontend/pages/foo.html

            * [Learn about view templates &rarr;](https://pakyow.com/docs/frontend/composition/)
        ERROR
      )
    end
  end

  context "context is a root path" do
    let :context do
      "/"
    end

    it "formats the message properly" do
      expect(error.contextual_message).to eq_sans_whitespace(
        <<~ERROR
          Pakyow couldn't render a view for `/`. Try creating a view template for this path:

              frontend/pages/index.html

            * [Learn about view templates &rarr;](https://pakyow.com/docs/frontend/composition/)
        ERROR
      )
    end
  end

  context "context is an empty string" do
    let :context do
      ""
    end

    it "formats the message properly" do
      expect(error.contextual_message).to eq_sans_whitespace(
        <<~ERROR
          Pakyow couldn't render a view for `/`. Try creating a view template for this path:

              frontend/pages/index.html

            * [Learn about view templates &rarr;](https://pakyow.com/docs/frontend/composition/)
        ERROR
      )
    end
  end

  context "context is nil" do
    let :context do
      nil
    end

    it "formats the message properly" do
      expect(error.contextual_message).to eq_sans_whitespace(
        <<~ERROR
          Pakyow couldn't render a view for `/`. Try creating a view template for this path:

              frontend/pages/index.html

            * [Learn about view templates &rarr;](https://pakyow.com/docs/frontend/composition/)
        ERROR
      )
    end
  end
end
