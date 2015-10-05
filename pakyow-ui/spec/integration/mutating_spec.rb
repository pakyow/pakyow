require_relative 'support/int_helper'

describe 'performing mutations' do
  before do
    class Post
      def self.create(params)
        params[:created] = true
        params
      end

      def self.all
        []
      end

      def self.find(id)
        { id: id }
      end
    end

    Pakyow::App.mutable :post do
      model Post

      action :create do |object|
        Post.create(object)
      end

      action :update do |object|
        object
      end

      query :all do
        Post.all
      end

      query :find do |id|
        Post.find(id.to_i)
      end
    end

    Pakyow::App.mutators :post do
      mutator :list do |view, data|
        PerformedMutations.perform(:list, view, data)
      end

      mutator :present, qualify: [:id] do |view, data|
        PerformedMutations.perform(:present, view, data)
      end
    end

    Pakyow::App.routes :post do
      get '/posts' do
        presenter.path = '/posts'
        view.scope(:post).mutate(:list, with: data(:post).all)
      end

      get '/posts/subscribe' do
        presenter.path = '/posts'
        view.scope(:post).mutate(:list, with: data(:post).all).subscribe
      end

      get '/posts/create' do
        data(:post).create(id: 2)
      end

      get '/posts/update/:id' do
        data(:post).update(id: params[:id], updating: true)
      end

      get '/posts/:post_id' do
        presenter.path = '/posts'
        view.scope(:post)[0].mutate(:present, with: data(:post).find(params[:post_id])).subscribe
      end

      get '/users/:user_id/posts' do
        presenter.path = '/posts'
        view.scope(:post).mutate(:list, with: data(:post).all).subscribe(user_id: params[:user_id])
      end

      get '/users/:user_id/posts/update/:id' do
        ui.mutated(:post, user_id: params[:user_id])
      end
    end

    Pakyow::App.stage(:test)
  end

  after do
    PerformedMutations.reset
    Pakyow::UI::SimpleMutationRegistry.instance.reset
  end

  let :performed do
    PerformedMutations.performed
  end

  let :post_id do
    1
  end

  let :other_post_id do
    post_id + 1
  end

  context 'and the mutation exists' do
    context 'and mutating a collection' do
      it 'calls the mutation for scope with name' do
        Pakyow.app.process(Rack::MockRequest.env_for('/posts'))
        expect(performed.keys).to include :list

        data = performed[:list][0][:data]
        expect(data).to eq(Post.all)
      end
    end

    context 'and mutating a view' do
      it 'calls the mutation for scope with name' do
        Pakyow.app.process(Rack::MockRequest.env_for("/posts/#{post_id}"))
        expect(performed.keys).to include :present

        data = performed[:present][0][:data]
        expect(data).to eq(Post.find(post_id))
      end
    end
  end

  context 'and the mutation is subscribed' do
    context 'and the mutations are unqualified' do
      before do
        Pakyow.app.process(Rack::MockRequest.env_for('/posts/subscribe'))
        PerformedMutations.reset
      end

      it 'calls the mutation again when a mutation occurs for the same scope' do
        Pakyow.app.process(Rack::MockRequest.env_for('/posts/create'))

        data = performed[:list][0][:data]
        expect(data).to eq(Post.all)
      end

      it 'does not call the mutation again when a mutation occurs for a different scope'
    end

    context 'and the mutations have qualifiers' do
      before do
        Pakyow.app.process(Rack::MockRequest.env_for("/posts/#{post_id}"))
        Pakyow.app.process(Rack::MockRequest.env_for("/posts/#{other_post_id}"))
        PerformedMutations.reset
      end

      context 'and the mutation occurs on data matching the qualification' do
        before do
          Pakyow.app.process(Rack::MockRequest.env_for("/posts/update/#{post_id}"))
        end

        it 'calls the qualified mutation again' do
          data = performed[:present][0][:data]
          expect(data).to eq(id: post_id)
        end

        it 'does not call an unqualified mutation again' do
          ids = performed[:present].map { |performance|
            performance[:data][:id]
          }

          expect(ids).not_to include(other_post_id)
        end
      end
    end

    context 'and the subscriptions are qualified' do
      let :user_id do
        1
      end

      let :other_user_id do
        user_id + 1
      end

      context 'and the mutation occurs in the same qualified manner' do
        before do
          Pakyow.app.process(Rack::MockRequest.env_for("/users/#{user_id}/posts"))
          PerformedMutations.reset

          Pakyow.app.process(Rack::MockRequest.env_for("/users/#{user_id}/posts/update/#{post_id}"))
        end

        it 'calls the mutation once' do
          expect(performed[:list].length).to eq(1)
        end
      end

      context 'and the mutation occurs in an unqualified manner' do
        before do
          Pakyow.app.process(Rack::MockRequest.env_for("/users/#{user_id}/posts"))
          PerformedMutations.reset

          Pakyow.app.process(Rack::MockRequest.env_for("/users/#{other_user_id}/posts/update/#{post_id}"))
        end

        it 'does not send the mutation' do
          expect(performed[:list]).to eq(nil)
        end
      end
    end
  end
end
