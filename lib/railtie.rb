require 'testbot'
if require('rails') rescue nil
  module Testbot
    class Railtie < Rails::Railtie
      rake_tasks do
        load File.expand_path(File.join(File.dirname(__FILE__), "tasks/testbot.rake"))
      end
    end
  end
end
