module ViewBindingHelpers
  def create_view_from_string(string)
    Pakyow::Presenter::View.new(string)
  end

  def view_helper(type)
    $views.fetch(type).dup
  end

  def ndoc_from_view(view)
    Oga.parse_html(view.to_s)
  end
end
