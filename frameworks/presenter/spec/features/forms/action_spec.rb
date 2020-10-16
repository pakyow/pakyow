RSpec.describe "setting a form action" do
  include_context "app"

  let :app_def do
    local = self
    Proc.new do
      resource :posts, "/presentation/forms/action" do
        new do
        end

        create do
        end
      end

      controller :foo, "/foo" do
        post :bar, "/bar" do
        end
      end

      presenter "/presentation/forms/action" do
        render node: -> { form(:post) } do
          setup do
            instance_exec(&local.form_setup)
          end
        end
      end
    end
  end

  context "action is a string" do
    let :form_setup do
      Proc.new do
        self.action = "/foo"
      end
    end

    it "sets the action" do
      expect(call("/presentation/forms/action")[2]).to include_sans_whitespace(
        <<~HTML
          <form data-b="post:form" action="/foo">
        HTML
      )
    end
  end

  context "action is a symbol" do
    context "endpoint is defined" do
      let :form_setup do
        Proc.new do
          self.action = :foo_bar
        end
      end

      it "sets the action" do
        expect(call("/presentation/forms/action")[2]).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form" action="/foo/bar" method="post">
          HTML
        )
      end
    end

    context "endpoint is not defined" do
      let :form_setup do
        Proc.new do
          self.action = :nonexistent
        end
      end

      it "does not set the action" do
        expect(call("/presentation/forms/action")[2]).to include_sans_whitespace(
          <<~HTML
            <form data-b="post:form">
          HTML
        )
      end
    end
  end
end
