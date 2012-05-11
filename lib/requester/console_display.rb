module Testbot::Requester
  class ConsoleDisplay 
    def initialize(requester)
      @requester = requester
    end

    def empty_line
      @requester.puts
    end

    def text(text, new_line = true)
      if new_line
        @requester.send(:puts, text)
      else
        @requester.send(:print, text)
        STDOUT.flush
      end
    end
  end
end
