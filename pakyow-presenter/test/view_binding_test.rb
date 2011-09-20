require 'helper'

class Contact < Struct.new(:full_name, :email)
end

class ViewBindingTest < Test::Unit::TestCase
  should "bind hash to view" do
    view = create_view_from_string(<<-D)
    <div class="contact">
      <span itemprop="full_name">John Doe</span>
      <a itemprop="email">john@example.com</a>
    </div>
    D
    data = {:full_name => "Jugyo Kohno", :email => "jugyo@example.com"}
    view.bind(data)

    assert_equal data[:full_name], view.doc.css('.contact span').first.content
    assert_equal data[:email],     view.doc.css('.contact a').first.content
  end

  should "bind an object to view" do
    view = create_view_from_string(<<-D)
    <div class="contact">
      <span itemprop="contact[full_name]">John Doe</span>
      <a itemprop="contact[email]">john@example.com</a>
    </div>
    D
    data = Contact.new("Jugyo Kohno", "jugyo@example.com")
    view.bind(data)

    assert_equal data[:full_name], view.doc.css('.contact span').first.content
    assert_equal data[:email],     view.doc.css('.contact a').first.content
  end

  should "bind an object to view with type" do
    view = create_view_from_string(<<-D)
    <div class="contact_info">
      <span itemprop="contact_info[full_name]">John Doe</span>
      <a itemprop="contact_info[email]">john@example.com</a>
    </div>
    D
    data = Contact.new("Jugyo Kohno", "jugyo@example.com")
    view.bind(data, "contact_info")

    assert_equal data[:full_name], view.doc.css('.contact_info span').first.content
    assert_equal data[:email],     view.doc.css('.contact_info a').first.content
  end

  should "bind an object to view by using 'name' attributes" do
    view = create_view_from_string(<<-D)
    <form class="contact">
      <input type="text" name="contact[full_name]" value="John Doe" />
      <input type="text" name="contact[email]" value="john@example.com" />
      <input type="submit" value="Submit" />
    </form>
    D
    data = Contact.new("Jugyo Kohno", "jugyo@example.com")
    view.bind(data)

    assert_equal data[:full_name], view.doc.css("input[name='contact[full_name]']").attr("value").value
    assert_equal data[:email],     view.doc.css("input[name='contact[email]']").attr("value").value
  end

  private

  def create_view_from_string(string)
    doc = Nokogiri::HTML::Document.parse(string)
    View.new(doc.root)
  end
end
