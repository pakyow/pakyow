module Pakyow
  class App
    concern :data

    stateful :model, Pakyow::Data::Model
  end
end
