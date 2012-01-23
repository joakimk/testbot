class RubyEnv

  def self.bundler?(project_path)
    Gem::Specification.find_by_name("bundler") && File.exists?("#{project_path}/Gemfile") rescue false
  end

  def self.ruby_command(project_path, opts = {})
    ruby_interpreter = opts[:ruby_interpreter] || "ruby"

    if opts[:script] && File.exists?("#{project_path}/#{opts[:script]}")
      command = opts[:script]
    elsif opts[:bin]
      command = opts[:bin]
    else
      command = ruby_interpreter
    end

    if bundler?(project_path)
      "#{ruby_interpreter} -S bundle exec #{command}"
    else
      "#{ruby_interpreter} -S #{command}"
    end
  end

end
