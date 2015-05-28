module ApplicationTestHelpers
  def app_test_path
    File.join('spec', 'support', 'helpers', 'app.rb')
  end

  def app(reset = false)
    if reset
      Pakyow::App.reset
    end

    Pakyow::App
  end
end
