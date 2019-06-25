RSpec.describe "setting a form method" do
  include_context "app"

  let :app_init do
    local = self
    Proc.new do
      resource :posts, "/presentation/forms/method" do
        new do
        end

        create do
        end
      end

      presenter "/presentation/forms/method" do
        render node: -> { form(:post) } do
          setup do
            instance_exec(&local.form_setup)
          end
        end
      end
    end
  end

  let :form_setup do
    Proc.new do
      self.method = :post
    end
  end

  it "sets the method" do
    expect(call("/presentation/forms/method")[2]).to include_sans_whitespace(
      <<~HTML
        <form data-b="post:form" method="post">
      HTML
    )
  end

  context "method requires an override" do
    let :form_setup do
      Proc.new do
        self.method = :patch
      end
    end

    it "sets the method" do
      expect(call("/presentation/forms/method")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form" method="post">
        HTML
      )
    end

    it "sets the override" do
      expect(call("/presentation/forms/method")[2]).to include_sans_whitespace(
        <<~HTML
          <input type="hidden" name="_method" value="patch">
        HTML
      )
    end
  end
end
