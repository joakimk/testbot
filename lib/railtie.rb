require 'testbot'
require 'rails'

module Testbot
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/testbot.rake"
    end
  end
end
