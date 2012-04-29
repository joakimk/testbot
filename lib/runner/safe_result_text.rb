require 'iconv'

module Testbot::Runner
  class SafeResultText
    def self.clean(text)
      clean_escape_sequences(strip_invalid_utf8(text))
    end

    def self.strip_invalid_utf8(text)
      # http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
      ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      ic.iconv(text + ' ')[0..-2]
    end

    def self.clean_escape_sequences(text)
      tail_marker = "^[[0m"
      tail = text.rindex(tail_marker) && text[text.rindex(tail_marker)+tail_marker.length..-1]
      if !tail
        text
      elsif tail.include?("^[[") && !tail.include?("m")
        text[0..text.rindex(tail_marker) + tail_marker.length - 1]
      elsif text.scan(/\[.*?m/).last != tail_marker
        text[0..text.rindex(tail_marker) + tail_marker.length - 1]
      else
        text
      end
    end
  end
end
