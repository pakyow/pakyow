require "helper"

class RouteStoreTest < Test::Unit::TestCase

  class RSTController
    def slash
      "slash"
    end

    def index
      "hello"
    end

    def r
      "found r"
    end

    def ss
      "found ss"
    end
    def sr
      "found sr"
    end

    def ts
      "found ts"
    end
    def tr
      "found tr"
    end

    def md
      "found md"
    end

    def mdend
      "found mdend"
    end

    def m1end
      "found m1end"
    end

    def dopost
      "found dopost"
    end

    def x1
      "found x1"
    end
    def x1x2
      "found x1x2"
    end

    def hook1
      "hook1"
    end

    def hook2
      "hook2"
    end

    def test1_hooks
      "test1_hooks"
    end
    
    def test2_hooks
      "test2_hooks"
    end

  end

  def setup
    @app = Pakyow::Application.new
    @route_store = RouteStore.new
    @app.route_store = @route_store
    @app.instance_eval {

      post '/isapost' do
        RSTController.new.dopost
      end

      get '/' do
        RSTController.new.slash
      end

      get '/index' do
        RSTController.new.index
      end

      get /^r[0-9]*$/ do
        RSTController.new.r
      end

      get '/s4' do
        RSTController.new.ss
      end
      get /^s[0-9]*$/ do
        RSTController.new.sr
      end

      get /^t[0-9]*$/ do
        RSTController.new.tr
      end
      get 't3' do
        RSTController.new.ts
      end

      get '/m1/:mid/d1/end' do
        RSTController.new.m1end
      end

      get 'm1/:mid/d1/:did' do
        RSTController.new.md
      end

      get '/m1/:mid/d1/:did/end' do
        RSTController.new.mdend
      end

      get '/x1/:id/:id2' do
        RSTController.new.x1
      end

      get '/x1/:id/:id2/x2' do
        RSTController.new.x1x2
      end

      restful 'bret', 'RouteStoreTest::RSTController' do
        restful 'anita', 'RouteStoreTest::RSTController'
      end

      hook :hook1 do
        RSTController.new.hook1
      end

      hook :hook2 do
        RSTController.new.hook2
      end

      get '/test1_hooks', :after => :hook1 do
        RSTController.new.test1_hooks
      end

      get '/test2_hooks', :after => [:hook1, :hook2], :before => :hook1 do
        RSTController.new.test2_hooks
      end

    }
  end

  def teardown
    # Do nothing
  end

  def test1_hooks
    proc,packet = @route_store.get_block('/test1_hooks', :get)
    assert_equal("/test1_hooks", packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    assert(proc, "No block found for /test1_hooks")
    assert_equal(['hook1'], proc.call)
  end

  def test2_hooks
    proc,packet = @route_store.get_block('/test2_hooks', :get)
    assert_equal("/test2_hooks", packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    assert(proc, "No block found for /test2_hooks")
    assert_equal(['hook1', 'hook2'], proc.call)
  end

  def test_isapost
    proc,packet = @route_store.get_block('/isapost', :get)
    assert_nil(proc, "Found a block for route GET /isapost")

    proc,packet = @route_store.get_block('/isapost', :post)
    assert_equal("/isapost", packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    assert(proc, "No block found for /isapost")
    assert_equal('found dopost', proc.call)
  end

  def test_slash_route
    proc,packet = @route_store.get_block('/', :get)
    assert_equal("/", packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    assert(proc, "No block found for /")
    assert_equal('slash', proc.call)
  end

  def test_index_route
    proc,packet = @route_store.get_block('index', :get)
    assert_equal("/index", packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    assert(proc, "No block found for index")
    assert_equal('hello', proc.call)
  end

  def test_regex_route
    proc,packet = @route_store.get_block('r', :get)
    assert_equal(/^r[0-9]*$/, packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    assert(proc, "No block found for r")
    assert_equal('found r', proc.call)
  end

  def test_string_over_regex
    proc,packet = @route_store.get_block('s4', :get)
    assert_equal("/s4", packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    assert(proc, "No block found for s4")
    assert_equal('found ss', proc.call)
  end

  def test_regex_after_string
    proc,packet = @route_store.get_block('/s10', :get)
    assert_equal(/^s[0-9]*$/, packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    assert(proc, "No block found for s10")
    assert_equal('found sr', proc.call)
  end

  def test_regex_block_string
    proc,packet = @route_store.get_block('/t3', :get)
    assert_equal(/^t[0-9]*$/, packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    assert(proc, "No block found for t3")
    assert_equal('found tr', proc.call)
  end

  def test_regex_before_string
    proc,packet = @route_store.get_block('/t9', :get)
    assert_equal(/^t[0-9]*$/, packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    assert(proc, "No block found for t9")
    assert_equal('found tr', proc.call)
  end

  def test_route_with_vars
    proc,packet = @route_store.get_block('m1/thx/d1/1138', :get)
    assert_equal("m1/:mid/d1/:did", packet[:data][:route_spec], "wrong route_spec")
    assert_nil(packet[:data][:restful], "restful data was not nil")
    v = packet[:vars]
    assert(proc, "No block found for m1/thx/d1/1138")
    assert_equal('found md', proc.call)
    assert_equal("thx", v['mid'])
    assert_equal("1138", v['did'])
  end

  def test_route_with_vars_not_at_end
    proc,packet = @route_store.get_block('/m1/1138/d1/thx/end', :get)
    assert_nil(packet[:data][:restful], "restful data was not nil")
    v = packet[:vars]
    assert(proc, "No block found for /m1/1138/d1/thx/end")
    assert_equal("1138", v['mid'])
  end

  def test_full_regex
    proc,packet = @route_store.get_block('/m1/new/d1/new', :get)
    assert_equal("m1/:mid/d1/:did", packet[:data][:route_spec], "wrong route_spec")
    v = packet[:vars]
    assert_equal('found md', proc.call)
    assert_equal("new", v['mid'])
    assert_equal("new", v['did'])

    proc,packet = @route_store.get_block('/m1/1138/d1/thx/end', :get)
    assert_equal("/m1/:mid/d1/:did/end", packet[:data][:route_spec], "wrong route_spec")
    v = packet[:vars]
    assert_equal('found mdend', proc.call)
    assert_equal("thx", v['did'])

    proc,packet = @route_store.get_block('/m1/11/d1/end', :get)
    assert_equal("/m1/:mid/d1/end", packet[:data][:route_spec], "wrong route_spec")
    v = packet[:vars]
    assert_equal('found m1end', proc.call)
    assert_equal("11", v['mid'])

    assert_nil(@route_store.get_block('m1/thx/d1/1138/new', :get)[0], "Found a block for route m1/thx/d1/1138/xxx")
    assert_nil(@route_store.get_block('m1/thx/d1/1138/xxx', :get)[0], "Found a block for route m1/thx/d1/1138/xxx")
    assert_nil(@route_store.get_block('/m1/1138/d1/thx/xxx', :get)[0], "Found a block for route /m1/1138/d1/thx/xxx")

    proc,packet = @route_store.get_block('/x1/one/two', :get)
    assert_equal('/x1/:id/:id2', packet[:data][:route_spec], "wrong route_spec")
    v = packet[:vars]
    assert_equal('found x1', proc.call)
    assert_equal("one", v['id'])
    assert_equal("two", v['id2'])

    proc,packet = @route_store.get_block('/x1/1/2/x2', :get)
    assert_equal('/x1/:id/:id2/x2', packet[:data][:route_spec], "wrong route_spec")
    v = packet[:vars]
    assert_equal('found x1x2', proc.call)
    assert_equal("1", v['id'])
    assert_equal("2", v['id2'])

    assert_nil(@route_store.get_block('/x1/1', :get)[0], "Found a block for route /x1/1")
  end

  def test_restful
    proc,packet = @route_store.get_block('/bret', :get)
    assert_equal("bret", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:index, packet[:data][:restful][:restful_action], "wrong restful action")

    proc,packet = @route_store.get_block('/bret/100', :get)
    assert_equal("bret/:id", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:show, packet[:data][:restful][:restful_action], "wrong restful action")
    assert_equal("100", packet[:vars]['id'], "wrong restful id value")

    proc,packet = @route_store.get_block('/bret/wen', :get)
    assert_equal("bret/:id", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:show, packet[:data][:restful][:restful_action], "wrong restful action")
    assert_equal("wen", packet[:vars]['id'], "wrong restful id value")

    proc,packet = @route_store.get_block('/bret/xnewx', :get)
    assert_equal("bret/:id", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:show, packet[:data][:restful][:restful_action], "wrong restful action")
    assert_equal("xnewx", packet[:vars]['id'], "wrong restful id value")

    proc,packet = @route_store.get_block('/bret/new', :get)
    assert_equal("bret/new", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:new, packet[:data][:restful][:restful_action], "wrong restful action")

    proc,packet = @route_store.get_block('/bret', :post)
    assert_equal("bret", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:create, packet[:data][:restful][:restful_action], "wrong restful action")

    proc,packet = @route_store.get_block('/bret/edit/11', :get)
    assert_equal("bret/edit/:id", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:edit, packet[:data][:restful][:restful_action], "wrong restful action")
    assert_equal("11", packet[:vars]['id'], "wrong restful ] id value")

    proc,packet = @route_store.get_block('/bret/357', :put)
    assert_equal("bret/:id", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:update, packet[:data][:restful][:restful_action], "wrong restful action")
    assert_equal("357", packet[:vars]['id'], "wrong restful id value")

    proc,packet = @route_store.get_block('/bret/468', :delete)
    assert_equal("bret/:id", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:delete, packet[:data][:restful][:restful_action], "wrong restful action")
    assert_equal("468", packet[:vars]['id'], "wrong restful id value")

    proc,packet = @route_store.get_block('/bret/100/anita', :get)
    assert_equal("bret/:_id/anita", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:index, packet[:data][:restful][:restful_action], "wrong restful action")

    proc,packet = @route_store.get_block('/bret/100/anita/234', :get)
    assert_equal("bret/:_id/anita/:id", packet[:data][:route_spec], "wrong route_spec")
    assert_equal(:show, packet[:data][:restful][:restful_action], "wrong restful action")
    assert_equal("100", packet[:vars]['_id'], "wrong restful bret_id value")
    assert_equal("234", packet[:vars]['id'], "wrong restful anita_id value")

  end

  def test_no_match
    assert_nil(@route_store.get_block('r123x', :get)[0], "Found a block for route r123x")
    assert_nil(@route_store.get_block('s123x', :get)[0], "Found a block for route s123x")
    assert_nil(@route_store.get_block('t123x', :get)[0], "Found a block for route t123x")
    assert_nil(@route_store.get_block('xxx', :get)[0], "Found a block for route xxx")
  end

end