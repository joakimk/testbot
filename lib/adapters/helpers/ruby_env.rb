class RubyEnv

  def self.bundler?(project_path)
    Gem.available?("bundler") && File.exists?("#{project_path}/Gemfile")
  end

end
