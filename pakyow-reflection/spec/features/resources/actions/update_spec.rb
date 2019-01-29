require_relative "./shared"

RSpec.describe "reflected resource update action" do
  include_context "resource action"

  let :frontend_test_case do
    "resources/actions/update"
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
    "/posts/#{updatable.one.id}"
  end

  let :method do
    :patch
  end

  let :form do
    {
      view_path: "/posts/edit",
      binding: "post:form"
    }
  end

  let :updatable do
    data.posts.create
  end

  let :nonupdatable do
    data.posts.create
  end

  before do
    updatable
    nonupdatable
  end

  it "updates the object with provided values, leaving other data unaltered" do
    expect {
      expect(response[0]).to eq(200)
    }.not_to change {
      data.posts.count
    }

    expect(updatable.reload.one.title).to eq(params[:post][:title])
    expect(updatable.reload.one.body).to eq(params[:post][:body])

    expect(nonupdatable.one.title).to eq(nil)
    expect(nonupdatable.one.body).to eq(nil)
  end

  context "object to update can't be found" do
    let :path do
      "/posts/#{updatable.one.id + 100}"
    end

    it "404s" do
      expect(response[0]).to eq(404)
    end
  end

  xcontext "passed a nested object" do
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

  xcontext "passed a value list" do
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

  xcontext "more than one form exists for the resource" do
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

  xcontext "more than one form exists for the resource in the same view template" do
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

  xcontext "resource is nested" do
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

  xcontext "without a valid authenticity token" do
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
    it "needs tests"
  end

  describe "redirecting after update" do
    it "needs tests"
  end

  describe "skipping the reflected behavior" do
    it "needs tests"
  end

  describe "validating the action" do
    it "needs tests"
  end
end
