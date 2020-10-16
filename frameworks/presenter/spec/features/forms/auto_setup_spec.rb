RSpec.describe "automatic form setup" do
  include_context "app"

  describe "auto rendering a form" do
    context "form has been setup" do
      let :app_def do
        Proc.new do
          resource :posts, "/posts" do
            new do
              expose "post:form", { title: "foo" }
              render "/form"
            end

            create do
            end
          end

          presenter "/form" do
            render node: -> { form(:post) } do
              setup do |form|
                form.bind(title: "bar")
              end
            end
          end
        end
      end

      it "does not setup again" do
        call("/posts/new").tap do |response|
          expect(response[0]).to eq(200)

          response[2].tap do |body|
            expect(body).to include_sans_whitespace(
              <<~HTML
                <input data-b="title" type="text" name="post[title]" value="bar">
              HTML
            )
          end
        end
      end
    end
  end

  describe "auto rendering a form for creating" do
    context "object is exposed for the form" do
      let :app_def do
        Proc.new do
          resource :posts, "/posts" do
            new do
              expose "post:form", { title: "foo" }
              render "/form"
            end

            create do
            end
          end
        end
      end

      it "sets up the form" do
        call("/posts/new").tap do |response|
          expect(response[0]).to eq(200)

          response[2].tap do |body|
            expect(body).to include_sans_whitespace(
              <<~HTML
                <form data-b="post:form" action="/posts" method="post">
              HTML
            )

            expect(body).not_to include_sans_whitespace(
              <<~HTML
                name="pw-http-method"
              HTML
            )
          end
        end
      end
    end

    context "no object is exposed for the form" do
      let :app_def do
        Proc.new do
          resource :posts, "/posts" do
            new do
              render "/form"
            end

            create do
            end
          end
        end
      end

      it "sets up the form" do
        call("/posts/new").tap do |response|
          expect(response[0]).to eq(200)

          response[2].tap do |body|
            expect(body).to include_sans_whitespace(
              <<~HTML
                <form data-b="post:form" action="/posts" method="post">
              HTML
            )

            expect(body).not_to include_sans_whitespace(
              <<~HTML
                name="pw-http-method"
              HTML
            )
          end
        end
      end
    end
  end

  describe "auto rendering a form for updating" do
    context "object is provided" do
      let :app_def do
        Proc.new do
          resource :posts, "/posts" do
            edit do
              expose "post:form", { id: params[:id], title: "foo" }
              render "/form"
            end

            update do
            end
          end
        end
      end

      it "sets up the form" do
        call("/posts/1/edit").tap do |response|
          expect(response[0]).to eq(200)

          response[2].tap do |body|
            expect(body).to include_sans_whitespace(
              <<~HTML
                <form data-b="post:form" action="/posts/1" method="post" data-id="1">
              HTML
            )

            expect(body).to include_sans_whitespace(
              <<~HTML
                <input type="hidden" name="pw-http-method" value="patch">
              HTML
            )
          end
        end
      end
    end

    context "no object is provided" do
      let :app_def do
        Proc.new do
          resource :posts, "/posts" do
            edit do
              render "/form"
            end

            update do
            end
          end
        end
      end

      it "sets up the form with params" do
        call("/posts/1/edit").tap do |response|
          expect(response[0]).to eq(200)

          response[2].tap do |body|
            expect(body).to include_sans_whitespace(
              <<~HTML
                <form data-b="post:form" action="/posts/1" method="post" data-id="1">
              HTML
            )

            expect(body).to include_sans_whitespace(
              <<~HTML
                <input type="hidden" name="pw-http-method" value="patch">
              HTML
            )
          end
        end
      end
    end
  end

  describe "auto rendering a form with options exposed in the presenter" do
    let :app_def do
      Proc.new do
        resource :posts, "/posts" do
          edit do
            expose "post:form", {
              id: params[:id], tag: "bar", colors: ["red", "blue"], enabled: false
            }

            render "/form/with-options"
          end

          update do
          end
        end

        presenter "/form/with-options" do
          render node: -> { form(:post) } do
            options_for(:tag, [[:foo, "Foo"], [:bar, "Bar"], [:baz, "Baz"]])
            options_for(:colors, [[:red, "Red"], [:green, "Green"], [:blue, "Blue"]])
            options_for(:enabled, [[true, "Yes"], [false, "No"]])
          end
        end
      end
    end

    it "selects the active option" do
      response = call("/posts/1/edit")
      expect(response[0]).to eq(200)

      body = response[2]

      expect(body).to include_sans_whitespace(
        <<~HTML
          <option value="foo">Foo</option>
          <option value="bar" selected="selected">Bar</option>
          <option value="baz">Baz</option>
        HTML
      )

      expect(body).to include_sans_whitespace(
        <<~HTML
          <input type="checkbox" data-b="colors" name="post[colors][]" value="red" checked="checked">
          <input type="checkbox" data-b="colors" name="post[colors][]" value="green">
          <input type="checkbox" data-b="colors" name="post[colors][]" value="blue" checked="checked">
        HTML
      )

      expect(body).to include_sans_whitespace(
        <<~HTML
          <input type="radio" data-b="enabled" name="post[enabled]" value="true">
          <input type="radio" data-b="enabled" name="post[enabled]" value="false" checked="checked">
        HTML
      )
    end
  end

  describe "auto rendering a form within a binding" do
    let :app_def do
      Proc.new do
        resource :posts, "/posts" do
          show do
            expose :post, { id: params[:id], title: "foo" }
            render "/form/within_binding"
          end

          resource :comments, "/comments" do
            create do
            end
          end
        end
      end
    end

    it "sets up the form" do
      call("/posts/1").tap do |response|
        expect(response[0]).to eq(200)

        response[2].tap do |body|
          expect(body).to include_sans_whitespace(
            <<~HTML
              <article data-b="post" data-id="1">
                <h1 data-b="title">foo</h1>

                <form data-b="comment:form" action="/posts/1/comments" method="post">
            HTML
          )
        end
      end
    end
  end
end
