require 'helper'

class LoaderTest < Test::Unit::TestCase
  def test_recursively_loads_files
    assert_raise(NameError) {
      Reloadable
    }
    
    l = Pakyow::Loader.new
    l.load!(path)
    
    assert_nothing_raised {
      Reloadable
    }
  end
  
  def test_should_tell_time
    Configuration::Base.app.auto_reload = true
    
    l = Pakyow::Loader.new
    l.load!(path)
    
    times = l.times.dup
    `touch #{path}/reloadable.rb`
    l.load!(path)
    
    assert_not_equal(times.first[1].to_f, l.times.first[1].to_f)
  end
  
  private
  
  def path
    File.join(Dir.pwd, 'test', 'loader')
  end
end

class Pakyow::Loader
  attr_accessor :times
end
