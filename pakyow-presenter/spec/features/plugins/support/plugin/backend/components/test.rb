component :test do
  def perform
    expose :ancestors, app.class.ancestors
  end

  presenter do
    def perform
      view.html = "plugin component render (ancestors: #{ancestors})"
    end
  end
end
