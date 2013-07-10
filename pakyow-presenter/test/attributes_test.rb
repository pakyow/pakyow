require 'support/helper'

class AttributesTest < Minitest::Test
  def setup
    Pakyow::App.stage(:test)
    @view_store = :test

    @coll = View.at_path("attributes", @view_store).scope(:attrs)
    @view = @coll[0]
  end

  def test_text_attributes_are_settable
    value = 'foo'
    @view.attrs.title = value
    assert_equal value, @view.attrs.title.to_s

    @coll.attrs.title = value
    assert_equal [value], @coll.attrs.title.map {|a| a.to_s}
  end

  def test_text_attributes_are_appendable
    value = 'foo'
    appended_value = 'bar'
    @view.attrs.title = value
    @view.attrs.title << appended_value
    assert_equal value + appended_value, @view.attrs.title.to_s
  end

  def test_text_attributes_are_ensurable
    value = 'foo'
    @view.attrs.title.ensure(value)
    assert_equal value, @view.attrs.title.to_s

    # do it again
    @view.attrs.title.ensure(value)
    assert_equal value, @view.attrs.title.to_s
  end

  def test_text_attributes_are_deletable
    value = 'foobar'
    @view.attrs.title = value
    @view.attrs.title.delete!('bar')
    assert_equal 'foo', @view.attrs.title.to_s
    @view.attrs.title.delete!('foo')
    assert_equal '', @view.attrs.title.to_s
  end

  def test_enum_attributes_are_settable
    value = 'foo'
    @view.attrs.class = [value]
    assert_equal value, @view.attrs.class.to_s
    @view.attrs.class = value
    assert_equal value, @view.attrs.class.to_s
  end

  def test_mult_attributes_are_appendable
    value = 'foo'
    appended_value = 'bar'
    @view.attrs.class = value
    @view.attrs.class << appended_value
    assert_equal "#{value} #{appended_value}", @view.attrs.class.to_s
  end

  def test_mult_attributes_are_ensurable
    value = 'foo'
    @view.attrs.class.ensure(value)
    assert_equal value, @view.attrs.class.to_s

    # do it again
    @view.attrs.class.ensure(value)
    assert_equal value, @view.attrs.class.to_s
  end

  def test_mult_attributes_handle_array_methods
    value = 'foo'
    @view.attrs.class.push(value)
    assert_equal value, @view.attrs.class.to_s
  end

  def test_bool_attributes_are_settable
    @view.attrs.disabled = true
    assert_equal true, @view.attrs.disabled.value
  end

  def test_bool_attributes_are_ensurable
    @view.attrs.disabled.ensure(true)
    assert_equal true, @view.attrs.disabled.value
  end

  def test_hash_attributes_are_settable
    @view.attrs.style[:color] = 'red'
    assert_equal 'color:red', @view.attrs.style.to_s

    @view.attrs.style = {color:'blue'}
    assert_equal 'color:blue', @view.attrs.style.to_s
  end

  def test_attributes_are_mass_assignable
    hash = { title: 'foo', class: 'bar' }

    @view.attrs(hash)
    assert_equal hash[:title], @view.attrs.title.to_s
    assert_equal hash[:class], @view.attrs.class.to_s
  end

  def test_attributes_are_modifiable_with_lambdas
    @view.attrs.title = 'foo'
    @view.attrs.title = lambda {|t| t + 'bar'}
    assert_equal 'foobar', @view.attrs.title.to_s

    @view.attrs.class = 'foo'
    @view.attrs.class = lambda {|c| c.push('bar')}
    assert_equal 'foo bar', @view.attrs.class.to_s
  end
end
