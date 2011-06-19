class Color
  def self.colorize(text, color)
    colors = { :green => 32, :orange => 33, :red => 31, :cyan => 36 }

    if colors[color]
      "\033[#{colors[color]}m#{text}\033[0m"
    else
      raise "Color not implemented: #{color}"
    end
  end

  def self.strip(text)
    text.gsub(/\e.+?m/, '')
  end
end

