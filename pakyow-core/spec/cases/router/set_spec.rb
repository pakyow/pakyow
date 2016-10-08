require 'support/helper'

RSpec.describe 'route set' do
  include ReqResHelpers
  include RouteTestHelpers

  before do
    Pakyow::App.stage(:test)
    @context = Pakyow::CallContext.new(mock_request.env)
    @context.instance_variable_set(:@context, Pakyow::AppContext.new(mock_request, mock_response))
  end

 it 'is registered and fetchable' do
    set = Pakyow::RouteEval.new

    fn1 = lambda {}
    fn2 = lambda {}

    set.eval {
      fn(:foo, &fn1)
      fn(:bar, &fn2)
    }

    expect(set.fn(:foo)).to eq fn1
    expect(set.fn(:bar)).to eq fn2
  end

  it 'is created and matched' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}

    set.eval {
      default(fn1)
    }

    expect(match: set.match('/', :get)).to have_same_path path: ""
    expect(match: set.match('/', :get)).to have_same_name name: :default
  end

  it 'creates and matches all routes' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}
    fn4 = lambda {}

    set.eval {
      get('get', fn1)
    }
    expect(match: set.match('get', :get)).to have_same_regex regex: 'get'
    expect(match: set.match('get', :get)).to have_same_vars vars: []
    expect(match: set.match('get', :get)).to have_same_name name: nil
    expect(match: set.match('get', :get)).to have_same_fns fns: fn1
    expect(match: set.match('get', :get)).to have_same_path path: 'get'

    set.eval {
      post('post', fn2)
    }
    expect(match: set.match('post', :post)).to have_same_regex regex: 'post'
    expect(match: set.match('post', :post)).to have_same_vars vars: []
    expect(match: set.match('post', :post)).to have_same_name name: nil
    expect(match: set.match('post', :post)).to have_same_fns fns: fn2
    expect(match: set.match('post', :post)).to have_same_path path: 'post'

    set.eval {
      put('put', fn3)
    }
    expect(match: set.match('put', :put)).to have_same_regex regex: 'put'
    expect(match: set.match('put', :put)).to have_same_vars vars: []
    expect(match: set.match('put', :put)).to have_same_name name: nil
    expect(match: set.match('put', :put)).to have_same_fns fns: fn3
    expect(match: set.match('put', :put)).to have_same_path path: 'put'

    set.eval {
      delete('delete', fn4)
    }
    expect(match: set.match('delete', :delete)).to have_same_regex regex: 'delete'
    expect(match: set.match('delete', :delete)).to have_same_vars vars: []
    expect(match: set.match('delete', :delete)).to have_same_name name: nil
    expect(match: set.match('delete', :delete)).to have_same_fns fns: fn4
    expect(match: set.match('delete', :delete)).to have_same_path path: 'delete'
  end

  it 'matches head as get' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}

    set.eval {
      get('get', fn1)
    }
    expect(match: set.match('get', :head)).to have_same_regex regex: 'get'
    expect(match: set.match('get', :head)).to have_same_vars vars: []
    expect(match: set.match('get', :head)).to have_same_name name: nil
    expect(match: set.match('get', :head)).to have_same_fns fns: fn1
    expect(match: set.match('get', :head)).to have_same_path path: 'get'
  end

  it 'handles unavailable req methods' do
    set = Pakyow::RouteSet.new
    expect { set.match('/', :foo) }.to_not raise_error
  end

  it 'accepts fn list for route' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}

    set.eval {
      fn(:foo, &fn1)
      get('foo', fn(:foo))
    }

    expect(set.match('foo', :get)[0][3][0]).to eq fn1
  end

  it 'can be defined without fn' do
    set = Pakyow::RouteSet.new

    set.eval {
      get('foo')
    }

    expect(set.match('foo', :get)).to_not be_nil
  end

  it 'can accept single fn' do
    set = Pakyow::RouteSet.new
    fn1 = lambda {}

    set.eval {
      get('foo', fn1)
    }

    expect(match: set.match('foo', :get)).to have_same_fns fns: fn1
  end

  it 'matches keyed routes' do
    set = Pakyow::RouteSet.new

    set.eval {
      get(':id') {}
    }

    expect(set.match('f/1', :get)).to be_nil
    expect(set.match('1', :post)).to be_nil
    expect(set.match('1', :get)).to_not be_nil
    expect(set.match('foo', :get)).to_not be_nil

    set = Pakyow::RouteSet.new

    set.eval {
      get('foo/:id') {}
    }

    expect(set.match('1', :get)).to be_nil
    expect(set.match('1', :post)).to be_nil
    expect(set.match('foo/1', :get)).to_not be_nil
    expect(set.match('foo/bar', :get)).to_not be_nil
  end

  it 'has vars that are extracted and available through request' do
    rtr = Pakyow::Router.instance
    rtr.set(:test) {
      get(':id') { }
    }

    %w(1 foo).each { |data|
      context = Pakyow::AppContext.new(mock_request("/#{data}"))
      Pakyow::Router.instance.perform(context)
      expect(context.request.params[:id]).to eq data
    }
  end

  it 'has regexp name captures that are extracted and available through request' do
    rtr = Pakyow::Router.instance
    rtr.set(:test) {
      get(/^foo\/(?<id>(\w|[-.~:@!$\'\(\)\*\+,;])*)$/) { }
    }

    %w(1 foo).each { |data|
      context = Pakyow::AppContext.new(mock_request("foo/#{data}"))
      Pakyow::Router.instance.perform(context)
      expect(context.request.params[:id]).to eq data
    }
  end

  it 'can be referenced by name' do
    set = Pakyow::RouteSet.new

    set.eval {
      get('foo', :foo) {}
    }

    expect(set.route(:foo)).to_not be_nil
    expect(set.route(:bar)).to be_nil
  end

  it 'can have name as first argument' do
    set = Pakyow::RouteSet.new

    set.eval {
      get(:foo, 'foo') {}
    }

    expect(set.route(:foo)).to_not be_nil
    expect(set.route(:bar)).to be_nil
  end

  it 'registers and matches handler' do
    set = Pakyow::RouteSet.new

    name = :err
    code = 500
    fn = lambda {}

    set.eval {
      handler(:err, 500, &fn)
    }

    expect(set.handle(name)).to have_same_handler [name, code, fn]
    expect(set.handle(code)).to have_same_handler [name, code, fn]
    expect(set.handle(404)).to be_nil
    expect(set.handle(:nf)).to be_nil
  end

  it 'can add hooks to route' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.eval {
      fn(:fn1, &fn1)
      fn(:fn2, &fn2)
      fn(:fn3, &fn3)
      get('1', fn(:fn1), before: fn(:fn2), after: fn(:fn3))
    }

    fns = set.match('1', :get)[0][3]
    expect(fns[0]).to eq fn2
    expect(fns[1]).to eq fn1
    expect(fns[2]).to eq fn3
  end

  it 'can add hooks to route in any order' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.eval {
      fn(:fn1, &fn1)
      fn(:fn2, &fn2)
      fn(:fn3, &fn3)
      get('2', fn(:fn1), after: fn(:fn3), before: fn(:fn2))
    }

    fns = set.match('2', :get)[0][3]
    expect(fns[0]).to eq fn2
    expect(fns[1]).to eq fn1
    expect(fns[2]).to eq fn3
  end

  it 'can add hooks to route by name' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.eval {
      fn(:fn1, &fn1)
      fn(:fn2, &fn2)
      fn(:fn3, &fn3)
      get('1', fn(:fn1), before: [:fn2], after: [:fn3])
    }

    fns = set.match('1', :get)[0][3]
    expect(fns[0]).to eq fn2
    expect(fns[1]).to eq fn1
    expect(fns[2]).to eq fn3
  end

  it 'hooks can be added to handler' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.eval {
      fn(:fn1, &fn1)
      fn(:fn2, &fn2)
      fn(:fn3, &fn3)
      handler(404, fn(:fn1), before: fn(:fn2), after: fn(:fn3))
      handler(401, fn(:fn1), after: fn(:fn3), before: fn(:fn2))
    }

    fns = set.handle(404)[2]
    expect(fns[0]).to eq fn2
    expect(fns[1]).to eq fn1
    expect(fns[2]).to eq fn3

    fns = set.handle(401)[2]
    expect(fns[0]).to eq fn2
    expect(fns[1]).to eq fn1
    expect(fns[2]).to eq fn3
  end

  it 'hooks can be added to handler by name' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.eval {
      fn(:fn1, &fn1)
      fn(:fn2, &fn2)
      fn(:fn3, &fn3)
      handler(404, fn(:fn1), before: [:fn2], after: [:fn3])
    }

    fns = set.handle(404)[2]
    expect(fns[0]).to eq fn2
    expect(fns[1]).to eq fn1
    expect(fns[2]).to eq fn3
  end

  it 'can match grouped routes' do
    set = Pakyow::RouteSet.new
    set.eval {
      group(:test_group) {
        default {}
      }
    }

    expect(set.match('/', :get)).to_not be_nil
  end

  it 'has grouped routes than can inherit hooks' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.eval {
      fn(:fn1, &fn1)
      fn(:fn2, &fn2)
      fn(:fn3, &fn3)

      group(:test_group, before: fn(:fn2), after: fn(:fn3)) {
        default(fn(:fn1))
      }
    }

    fns = set.match('/', :get)[0][3]
    expect(fns[0]).to eq fn2
    expect(fns[1]).to eq fn1
    expect(fns[2]).to eq fn3
  end

  it 'can be matched by namespace' do
    set = Pakyow::RouteSet.new

    set.eval {
      namespace('foo', :test_ns) {
        get('bar') {}
      }
    }

    expect(set.match('/foo/bar', :get)).to_not be_nil
    expect(set.match('/bar', :get)).to be_nil
  end

  it 'have namespaced names as first argument' do
    set = Pakyow::RouteSet.new

    set.eval {
      namespace(:test_ns, 'foo') {
        get('bar') {}
      }
    }

    expect(set.match('/foo/bar', :get)).to_not be_nil
    expect(set.match('/bar', :get)).to be_nil
  end

  it 'with namespaced routes can inherit hooks' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.eval {
      fn(:fn1, &fn1)
      fn(:fn2, &fn2)
      fn(:fn3, &fn3)

      namespace('foo', :test_ns, before: fn(:fn2), after: fn(:fn3)) {
        default(fn(:fn1))
      }
    }

    fns = set.match('/foo', :get)[0][3]
    expect(fns[0]).to eq fn2
    expect(fns[1]).to eq fn1
    expect(fns[2]).to eq fn3
  end

  it 'route templates can be defined and expanded' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}

    set.eval {
      template(:test_template) {
        get '/', :root
      }

      expand(:test_template, :test_expansion, 'foo') {
        action(:root, &fn1)
      }
    }

    expect(set.match('/foo', :get)[0][3][0]).to eq fn1
  end

  it 'templates can be expanded dynamically' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}

    set.eval {
      template(:test_template) {
        get '/', :root
      }

      test_template(:test_expansion, 'foo') {
        root(&fn1)
      }
    }

    expect(set.match('/foo', :get)[0][3][0]).to eq fn1
  end

  it 'route templates can define hooks for actions' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.eval {
      template(:test_template) {
        get '/', :root, before: fn1
      }

      test_template(:test_expansion, 'foo') {
        root(before: fn2, after: fn3)
      }
    }

    fns = set.match('/foo', :get)[0][3]

    expect(fns[0]).to eq fn1 # hooks defined in template have priority
    expect(fns[1]).to eq fn2
    expect(fns[2]).to eq fn3
  end

  it 'route templates can define groups' do
    set = Pakyow::RouteSet.new

    set.eval {
      template(:test_template) {
        group :ima_group
      }

      test_template(:test_expansion, 'foo') {
        ima_group {
          get('grouped')
        }
      }
    }

    expect(set.match('/foo/grouped', :get)).to be_truthy
  end

  it 'route template groups handle hooks' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.eval {
      template(:test_template) {
        group :ima_group, before: fn1
      }

      test_template(:test_expansion, 'foo') {
        ima_group(before: fn2, after: fn3) {
          get('grouped')
        }
      }
    }

    fns = set.match('/foo/grouped', :get)[0][3]

    expect(fns[1]).to eq fn1
    expect(fns[0]).to eq fn2 # hooks defined in expansion have priority
    expect(fns[2]).to eq fn3
  end

  it 'route templates can define namespaces' do
    set = Pakyow::RouteSet.new

    set.eval {
      template(:test_template) {
        namespace :ima_namespace, 'ns'
      }

      test_template(:test_expansion, 'foo') {
        ima_namespace {
          get('namespaced')
        }
      }
    }

    expect(set.match('/foo/ns/namespaced', :get)).to be_truthy
  end

  it 'route template namespaces handle hooks' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}
    fn3 = lambda {}

    set.eval {
      template(:test_template) {
        namespace :ima_namespace, 'ns', before: fn1
      }

      test_template(:test_expansion, 'foo') {
        ima_namespace(before: fn2, after: fn3) {
          get('namespaced')
        }
      }
    }

    fns = set.match('/foo/ns/namespaced', :get)[0][3]

    expect(fns[1]).to eq fn1
    expect(fns[0]).to eq fn2 # hooks defined in expansion have priority
    expect(fns[2]).to eq fn3
  end

  it 'routes can be defined in template expansion' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}

    set.eval {
      template(:test_template) {
      }

      expand(:test_template, :test_expansion, 'foo') {
        get '/bar', fn1
      }
    }

    expect(fn1).to eq set.match('/foo/bar', :get)[0][3][0]
  end

  it 'can expand nested templates' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}

    set.eval {
      template(:test_template) {
        get '/', :root
      }

      expand(:test_template, :test_expansion, 'foo') {
        root fn1

        expand(:test_template, :nested_expansion, 'bar') {
          root fn2
        }
      }
    }

    expect(set.match('/foo', :get)[0][3][0]).to eq fn1
    expect(set.match('/foo/bar', :get)[0][3][0]).to eq fn2
  end

  it 'route paths can be overridden' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}

    set.eval {
      template(:test_template) {
        routes_path { |path| File.join(path, 'bar') }

        get '/', :root
      }

      expand(:test_template, :test_expansion, 'foo') {
        get '/foo', fn1
        root fn2
      }
    }

    expect(set.match('/foo/bar/foo', :get)[0][3][0]).to eq fn1
    expect(set.match('/foo/bar', :get)[0][3][0]).to eq fn2
  end

  it 'nested path can be overridden' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}

    set.eval {
      template(:test_template) {
        nested_path { |path| File.join(path, 'nested') }

        get '/', :root
      }

      expand(:test_template, :test_expansion, 'foo') {
        expand(:test_template, :nested_expansion, 'bar') {
          root fn1
        }
      }
    }

    expect(set.match('/foo/nested/bar', :get)[0][3][0]).to eq fn1
  end

  it 'templates can expand without name' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}

    set.eval {
      template(:test_template) {
      }

      expand(:test_template) {
        get '/', &fn1
      }
    }

    expect(set.match('/', :get)[0][3][0]).to eq fn1
  end

  it 'hooks defined with templates are used' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}

    set.eval {
      template(:test_template, before: fn1) {
      }

      expand(:test_template) {
        get '/', &fn2
      }
    }

    fns = set.match('/', :get)[0][3]

    expect(fns[0]).to eq fn1
    expect(fns[1]).to eq fn2
  end

  it 'nested group will inherits hooks' do
    set = Pakyow::RouteSet.new

    fn1 = lambda {}
    fn2 = lambda {}

    set.eval {
      group(:first_group, before: fn1) {
        group(:second_group) {
          get '/', &fn2
        }
      }
    }

    fns = set.match('/', :get)[0][3]

    expect(fns[0]).to eq fn1
    expect(fns[1]).to eq fn2
  end
end
