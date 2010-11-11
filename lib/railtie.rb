require 'testbot'
require 'rails'

module Testbot
  class Railtie < Rails::Railtie
    railtie_name :testbot

    rake_tasks do
      load "tasks/testbot.rake"
    end
  end
end
