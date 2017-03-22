RSpec.describe "defining resources" do
  include_context "testable app"

  context "when the resource is defined at the top level" do
    let :app_definition do
      -> {
        resource :post, "/posts" do
          list do
            send "post list"
          end
        end
      }
    end

    it "defines the resource" do
      res = call("/posts")
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("post list")
    end
  end

  context "when the resource is nested within another resource" do
    let :app_definition do
      -> {
        resource :post, "/posts" do
          resource :comment, "/comments" do
            list do
              send "post #{params[:post_id]} comment list"
            end
          end
        end
      }
    end

    it "defines the resource" do
      res = call("/posts/1/comments")
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("post 1 comment list")
    end
  end

  context "when the resource is defined with hooks" do
    let :app_definition do
      -> {
        resource :post, "/posts", before: [:validate] do
          def validate
            send "validate"
          end

          list do
            send "list"
          end
        end
      }
    end

    it "calls the resource's hooks" do
      res = call("/posts")
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("validate")
    end

    context "and the resource route defines its own hooks" do
      let :app_definition do
        -> {
          resource :post, "/posts", before: [:validate] do
            def validate
              $calls << :validate
            end

            def foo
              $calls << :foo
            end

            list before: [:foo] do
              send "list"
            end
          end
        }
      end

      before do
        $calls = []
      end

      it "calls all the hooks" do
        res = call("/posts")
        expect(res[0]).to eq(200)
        expect(res[2].body.read).to eq("list")
        expect($calls[0]).to eq(:validate)
        expect($calls[1]).to eq(:foo)
      end
    end
  end

  context "when the resource is defined partially" do
    let :app_definition do
      -> {
        resource :post, "/posts" do
          list do
          end
        end
      }
    end

    it "does not respond to undefined routes" do
      expect(call("/posts/new")[0]).to eq(404)
    end
  end

  context "when the resource is extended with member routes" do
    let :app_definition do
      -> {
        resource :post, "/posts" do
          member do
            get "/member"
          end
        end
      }
    end

    it "properly defines the member routes" do
      expect(call("/posts/123/member")[0]).to eq(200)
    end
  end

  context "when the resource is extended with collection routes" do
    let :app_definition do
      -> {
        resource :post, "/posts" do
          collection do
            get "/collection"
          end
        end
      }
    end

    it "properly defines the collection routes" do
      expect(call("/posts/collection")[0]).to eq(200)
    end
  end

  describe "the defined resource" do
    let :app_definition do
      -> {
        resource :post, "/posts" do
          list do
            send "post list"
          end

          new do
            send "post new"
          end

          create do
            send "post create"
          end

          edit do
            send "post #{params[:post_id]} edit"
          end

          update do
            send "post #{params[:post_id]} update"
          end

          replace do
            send "post #{params[:post_id]} replace"
          end

          remove do
            send "post #{params[:post_id]} remove"
          end

          show do
            send "post #{params[:post_id]} show"
          end
        end
      }
    end

    it "can have a list action" do
      res = call("/posts")
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("post list")
    end

    it "can have a new action" do
      res = call("/posts/new")
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("post new")
    end

    it "can have a create action" do
      res = call("/posts", method: :post)
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("post create")
    end

    it "can have a edit action" do
      res = call("/posts/1/edit")
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("post 1 edit")
    end

    it "can have a update action" do
      res = call("/posts/1", method: :patch)
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("post 1 update")
    end

    it "can have a replace action" do
      res = call("/posts/1", method: :put)
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("post 1 replace")
    end

    it "can have a remove action" do
      res = call("/posts/1", method: :delete)
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("post 1 remove")
    end

    it "can have a show action" do
      res = call("/posts/1")
      expect(res[0]).to eq(200)
      expect(res[2].body.read).to eq("post 1 show")
    end
  end
end
