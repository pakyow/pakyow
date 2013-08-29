class Contact
  attr_accessor :full_name, :email

  def initialize(full_name, email)
    @full_name = full_name
    @email = email
  end

  def [](key)
    send(key)
  end
end

class ViewBindingTest < Minitest::Test
  def setup
    @view = create_view_from_string(<<-D)
    <div class="contact" data-scope="contact">
      <span data-prop="full_name">John Doe</span>
      <a data-prop="email">john@example.com</a>
    </div>
    D
  end

  def test_should_bind_hash
    data = {:full_name => "Jugyo Kohno", :email => "jugyo@example.com"}
    @view.scope(:contact).bind(data)

    assert_equal data[:full_name], @view.doc.css('.contact span').first.content
    assert_equal data[:email],     @view.doc.css('.contact a').first.content
  end

  def test_should_bind_object
    data = Contact.new("Jugyo Kohno", "jugyo@example.com")
    @view.scope(:contact).bind(data)

    assert_equal data[:full_name], @view.doc.css('.contact span').first.content
    assert_equal data[:email],     @view.doc.css('.contact a').first.content
  end

  # def test_should_map_content_to_value
  #   view = create_view_from_string(<<-D)
  #   <div class="contact" data-scope="contact">
  #     <input type="text" data-prop="full_name">
  #   </div>
  #   D
  #
  #   data = { full_name: 'foo' }
  #   view.scope(:contact).bind(data)
  #
  #   assert_equal data[:full_name], view.doc.css('.contact input').first.get_attribute('value')
  # end

  #TODO test name on input is autoset

  private

  def create_view_from_string(string)
    doc = Nokogiri::HTML::Document.parse(string)
    View.from_doc(doc.root)
  end
end
