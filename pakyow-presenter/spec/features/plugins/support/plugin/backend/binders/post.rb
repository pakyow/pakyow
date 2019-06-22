binder :post do
  def plugged_title
    "#{@app.config.name}: #{object[:title]}"
  end
end
