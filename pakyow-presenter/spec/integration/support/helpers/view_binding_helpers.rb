module ViewBindingHelpers
  def create_view_from_string(string)
    Pakyow::Presenter::View.new(string)
  end

  def view_helper(type)
    $views.fetch(type).dup
  end

  def ndoc_from_view(view)
    Nokogiri::HTML.fragment(view.to_s)
  end
end
