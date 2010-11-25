require 'testbot'

begin
  require 'rails'
  @rails_loaded = true
rescue LoadError => ex
  @rails_loaded = false
end

if @rails_loaded
  module Testbot
    class Railtie < Rails::Railtie
      rake_tasks do
        load File.expand_path(File.join(File.dirname(__FILE__), "tasks/testbot.rake"))
      end
    end
  end
end
