RSpec.describe "setting up a form with method override" do
  include_context "app"

  let :app_def do
    local = self
    Proc.new do
      resource :posts, "/presentation/forms/method_override" do
        new do
        end

        create do
        end
      end

      presenter "/presentation/forms/method_override" do
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
    end
  end

  it "does not set the override by default" do
    expect(call("/presentation/forms/method_override")[2]).not_to include_sans_whitespace(
      <<~HTML
        pw-http-method
      HTML
    )
  end

  context "method is set" do
    context "method does not require an override" do
      let :form_setup do
        Proc.new do
          self.method = :post
        end
      end

      it "does not set the override" do
        expect(call("/presentation/forms/method_override")[2]).not_to include_sans_whitespace(
          <<~HTML
            pw-http-method
          HTML
        )
      end
    end

    context "method requires an override" do
      let :form_setup do
        Proc.new do
          self.method = :patch
        end
      end

      it "sets the override" do
        expect(call("/presentation/forms/method_override")[2]).to include_sans_whitespace(
          <<~HTML
            <input type="hidden" name="pw-http-method" value="patch">
          HTML
        )
      end
    end
  end
end
