require_relative "./shared"

RSpec.describe "reflected resource create action" do
  include_context "resource action"

  let :frontend_test_case do
    "resources/actions/create"
  end

  let :values do
    {
      post: {
        title: "post one",
        body: "this is the first post"
      }
    }
  end

  let :path do
    "/posts"
  end

  it "creates an object with provided values" do
    expect {
      expect(response[0]).to eq(200)
    }.to change {
      data.posts.count
    }.from(0).to(1)

    expect(data.posts[0].title).to eq(params[:post][:title])
    expect(data.posts[0].body).to eq(params[:post][:body])
  end

  context "passed a nested object" do
    let :frontend_test_case do
      "resources/actions/create_with_nested_object"
    end

    let :values do
      {
        user: {
          name: "Ferdinand",

          link: {
            url: "https://bryanp.org"
          }
        }
      }
    end

    let :path do
      "/users"
    end

    let :form do
      super().tap do |form|
        form[:binding] = "user:form"
      end
    end

    let :reflected_app_init do
      Proc.new do
        source :users do
          has_one :link
        end
      end
    end

    it "creates the object with nested objects associated to it" do
      expect {
        expect(response[0]).to eq(200)
      }.to change {
        data.users.count
      }.from(0).to(1)

      user = data.users.including(:link)[0]
      expect(user.name).to eq(values[:user][:name])

      expect(user.link.url).to eq(values[:user][:link][:url])
    end

    context "objects already exists" do
      let :values do
        {
          user: {
            name: "Ferdinand",

            link: {
              id: 1,
              url: "https://bryanp.org"
            }
          }
        }
      end

      before do
        data.links.create(url: "http://bryanp.org")
      end

      it "creates the object with nested objects associated to it" do
        expect {
          expect(response[0]).to eq(200)
        }.to change {
          data.users.count
        }.from(0).to(1)

        user = data.users.including(:link)[0]
        expect(user.name).to eq(values[:user][:name])

        expect(user.link.url).to eq(values[:user][:link][:url])
      end

      it "updates the existing object instead of creating another one" do
        expect {
          response
        }.not_to change {
          data.links.count
        }
      end
    end
  end

  context "passed a value list" do
    context "values are for an attribute" do
      let :frontend_test_case do
        "resources/actions/create_with_value_list_as_attribute"
      end

      let :values do
        {
          user: {
            name: "Ferdinand",

            links: [
              "https://bryanp.org",
              "https://metabahn.com",
              "https://pakyow.com"
            ]
          }
        }
      end

      let :path do
        "/users"
      end

      let :form do
        super().tap do |form|
          form[:binding] = "user:form"
        end
      end

      it "creates the object with the value list" do
        expect {
          expect(response[0]).to eq(200)
        }.to change {
          data.users.count
        }.from(0).to(1)

        expect(data.users[0].name).to eq(values[:user][:name])
        expect(data.users[0].links).to eq(values[:user][:links].inspect)
      end
    end

    context "values are for nested objects" do
      let :frontend_test_case do
        "resources/actions/create_with_value_list_as_object"
      end

      let :values do
        {
          user: {
            name: "Ferdinand",

            links: [
              { url: "https://bryanp.org" },
              { url: "https://metabahn.com" },
              { url: "https://pakyow.com" }
            ]
          }
        }
      end

      let :path do
        "/users"
      end

      let :form do
        super().tap do |form|
          form[:binding] = "user:form"
        end
      end

      it "creates the object with nested objects associated to it" do
        expect {
          expect(response[0]).to eq(200)
        }.to change {
          data.users.count
        }.from(0).to(1)

        user = data.users.including(:links)[0]
        expect(user.name).to eq(values[:user][:name])

        expect(user.links.count).to eq(3)
        expect(user.links[0].url).to eq(values[:user][:links][0][:url])
        expect(user.links[1].url).to eq(values[:user][:links][1][:url])
        expect(user.links[2].url).to eq(values[:user][:links][2][:url])
      end

      context "objects already exists" do
        let :values do
          {
            user: {
              name: "Ferdinand",

              links: [
                { id: 1, url: "https://bryanp.org" }
              ]
            }
          }
        end

        before do
          data.links.create(url: "http://bryanp.org")
        end

        it "creates the object with nested objects associated to it" do
          expect {
            expect(response[0]).to eq(200)
          }.to change {
            data.users.count
          }.from(0).to(1)

          user = data.users.including(:links)[0]
          expect(user.name).to eq(values[:user][:name])

          expect(user.links.count).to eq(1)
          expect(user.links[0].url).to eq(values[:user][:links][0][:url])
        end

        it "updates the existing object instead of creating another one" do
          expect {
            response
          }.not_to change {
            data.links.count
          }
        end
      end
    end
  end

  context "more than one form exists for the resource" do
    let :frontend_test_case do
      "resources/actions/create_multiple_forms"
    end

    it "handles the correct form submission" do
      # The root form only contains title, so the post shouldn't be created with a body.
      #
      expect {
        expect(response[0]).to eq(200)
      }.to change {
        data.posts.count
      }.from(0).to(1)

      expect(data.posts[0].title).to eq(params[:post][:title])
      expect(data.posts[0].body).to be(nil)
    end
  end

  context "more than one form exists for the resource in the same view template" do
    let :frontend_test_case do
      "resources/actions/create_multiple_forms_same_view_template"
    end

    let :form do
      super().tap do |form|
        form[:binding] = "post:form:bar"
      end
    end

    it "handles the correct form submission" do
      # The bar form only contains title, so the post shouldn't be created with a body.
      #
      expect {
        expect(response[0]).to eq(200)
      }.to change {
        data.posts.count
      }.from(0).to(1)

      expect(data.posts[0].title).to eq(params[:post][:title])
      expect(data.posts[0].body).to be(nil)
    end
  end

  context "resource is nested" do
    let :frontend_test_case do
      "resources/actions/create_nested_scope"
    end

    before do
      data.posts.create
    end

    let :values do
      {
        comment: {
          body: "comment one"
        }
      }
    end

    let :path do
      "/posts/#{data.posts[0].id}/comments"
    end

    let :form do
      super().tap do |form|
        form[:binding] = "post:article:form"
        form[:view_path] = "/posts/show"
      end
    end

    it "creates an object with provided values and associates to the parent object" do
      expect {
        expect(response[0]).to eq(200)
      }.to change {
        data.comments.count
      }.from(0).to(1)

      comment = data.comments.including(:post)[0]
      expect(comment.body).to eq(values[:comment][:body])
      expect(comment.post).to eq(data.posts[0])
    end

    context "parent object can't be found" do
      let :path do
        "/posts/#{data.posts[0].id + 1}/comments"
      end

      it "returns 404" do
        expect {
          expect(response[0]).to eq(404)
        }.not_to change {
          data.comments.count
        }
      end
    end
  end

  context "without a valid authenticity token" do
    let :authenticity_token do
      "foo:bar"
    end

    it "fails to create an object for the passed values" do
      expect {
        expect(response[0]).to eq(403)
      }.not_to change {
        data.posts.count
      }
    end
  end

  context "resource is already defined" do
    context "reflected action is not defined in the existing resource" do
      it "defines the reflected action"
    end

    context "action is defined in the existing resource that matches the reflected action" do
      it "does not override the existing action"
      it "attaches the reflect behavior"
    end
  end

  describe "redirecting after create" do
    context "form origin is passed" do
      let :form do
        super().tap do |form|
          form[:origin] = origin
        end
      end

      let :origin do
        "/"
      end

      context "form origin is new" do
        let :origin do
          "/posts/new"
        end

        context "show endpoint is defined" do
          let :reflected_app_init do
            Proc.new do
              resource :posts, "/posts" do
                show
              end
            end
          end

          it "redirects to show" do
            expect(response[0]).to eq(302)
            expect(response[1]["Location"]).to eq("/posts/#{Pakyow.apps.first.data.posts.first.id}")
          end
        end

        context "list endpoint is defined" do
          let :reflected_app_init do
            Proc.new do
              resource :posts, "/posts" do
                list
              end
            end
          end

          it "redirects to list" do
            expect(response[0]).to eq(302)
            expect(response[1]["Location"]).to eq("/posts")
          end
        end

        context "both show and list endpoints are defined" do
          let :reflected_app_init do
            Proc.new do
              resource :posts, "/posts" do
                list
                show
              end
            end
          end

          it "redirects to show" do
            expect(response[0]).to eq(302)
            expect(response[1]["Location"]).to eq("/posts/1")
          end
        end

        context "neither the show nor list endpoints are defined" do
          it "does not redirect" do
            expect(response[0]).to eq(200)
          end
        end
      end

      context "form origin is something other than new" do
        let :origin do
          "/foo"
        end

        it "redirects to the form origin" do
          expect(response[0]).to eq(302)
          expect(response[1]["Location"]).to eq("/foo")
        end
      end
    end

    context "form origin is not passed" do
      let :form do
        super().tap do |form|
          form[:origin] = nil
        end
      end

      it "does not redirect" do
        expect(response[0]).to eq(200)
      end
    end
  end

  describe "skipping the reflected behavior" do
    let :reflected_app_init do
      Proc.new do
        resource :posts, "/posts" do
          skip_action :reflect

          create do
            send "hello"
          end
        end
      end
    end

    it "skips the reflected behavior, but calls the route" do
      expect(response[0]).to eq(200)
      expect(response[2].body.read).to eq("hello")
    end
  end

  describe "validating the action" do
    context "passed some attributes" do
      let :params do
        super().tap do |params|
          params[:post].delete(:body)
        end
      end

      it "succeeds, setting passed values" do
        expect {
          expect(response[0]).to eq(200)
        }.to change {
          Pakyow.apps.first.data.posts.count
        }.from(0).to(1)

        post = Pakyow.apps.first.data.posts.first
        expect(post.title).to eq(params[:post][:title])
        expect(post.body).to be(nil)
      end
    end

    context "passed an attribute not present in the form" do
      let :reflected_app_init do
        Proc.new do
          source :posts do
            attribute :published, :boolean, default: false
          end
        end
      end

      let :params do
        super().tap do |params|
          params[:post][:published] = true
        end
      end

      it "succeeds, ignoring the unexpected value" do
        expect {
          expect(response[0]).to eq(200)
        }.to change {
          Pakyow.apps.first.data.posts.count
        }.from(0).to(1)

        expect(Pakyow.apps.first.data.posts.first.published).to be(false)
      end
    end

    context "passed no attributes" do
      let :params do
        super().tap do |params|
          params[:post] = {}
        end
      end

      it "fails" do
        expect {
          expect(response[0]).to eq(400)
        }.not_to change {
          Pakyow.apps.first.data.posts.count
        }
      end
    end

    context "type is not passed in params" do
      let :params do
        super().tap do |params|
          params.delete(:post)
        end
      end

      it "fails" do
        expect {
          expect(response[0]).to eq(400)
        }.not_to change {
          Pakyow.apps.first.data.posts.count
        }
      end
    end

    describe "required attributes" do
      let :frontend_test_case do
        "resources/actions/required_create"
      end

      context "passed the required attribute" do
        it "succeeds, setting passed values" do
          expect {
            expect(response[0]).to eq(200)
          }.to change {
            Pakyow.apps.first.data.posts.count
          }.from(0).to(1)

          post = Pakyow.apps.first.data.posts.first
          expect(post.title).to eq(params[:post][:title])
          expect(post.body).to eq(params[:post][:body])
        end
      end

      context "required attribute is missing" do
        let :params do
          super().tap do |params|
            params[:post].delete(:body)
          end
        end

        it "fails" do
          expect {
            expect(response[0]).to eq(400)
          }.not_to change {
            Pakyow.apps.first.data.posts.count
          }
        end
      end
    end

    describe "attributes with a pattern" do
      it "needs tests"
    end

    describe "attributes with a min lenth" do
      it "needs tests"
    end

    describe "attributes with a max length" do
      it "needs tests"
    end

    describe "attributes with a min and max length" do
      it "needs tests"
    end

    describe "email attributes" do
      it "needs tests"
    end

    describe "tel attributes" do
      it "needs tests"
    end

    describe "url attributes" do
      it "needs tests"
    end
  end
end
