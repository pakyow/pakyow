class ViewFormBindingTest < Minitest::Test
  def setup
    @view = create_view_from_string(<<-D)
    <form data-scope="foo">
      <input data-prop="unnamed">
      <input data-prop="named" name="name">
      <input data-prop="valued" value="value">
    </form>
    D
  end

  def test_binding_to_unnamed_field_sets_name
    capture_stdout {
      @view.scope(:foo).bind(unnamed: 'test')
      assert_equal "foo[unnamed]", @view.scope(:foo).prop(:unnamed)[0].attrs.name.to_s
    }
  end

  def test_binding_to_named_field_does_not_set_name
    capture_stdout {
      @view.scope(:foo).bind(named: 'test')
      assert_equal "name", @view.scope(:foo).prop(:named)[0].attrs.name.to_s
    }
  end

  def test_binding_to_unvalued_field_sets_value
    capture_stdout {
      @view.scope(:foo).bind(unnamed: 'test')
      assert_equal "test", @view.scope(:foo).prop(:unnamed)[0].attrs.value.to_s
    }
  end

  def test_binding_to_unvalued_field_does_not_set_value
    capture_stdout {
      @view.scope(:foo).bind(valued: 'test')
      assert_equal "value", @view.scope(:foo).prop(:valued)[0].attrs.value.to_s
    }
  end

  private

  def create_view_from_string(string)
    doc = Nokogiri::HTML::Document.parse(string)
    View.from_doc(doc.root)
  end
end
