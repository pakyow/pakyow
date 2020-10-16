component :test do
  def perform
    expose :ancestors, app.class.ancestors
  end

  presenter do
    render node: -> { self } do
      self.html = "plugin component render (ancestors: #{ancestors})"
    end
  end
end
