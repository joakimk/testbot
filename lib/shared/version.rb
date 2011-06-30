module Testbot
  # Don't forget to update readme and changelog
  def self.version
    version = "0.5.9"
    dev_version_file = File.join(File.dirname(__FILE__), '..', '..', 'DEV_VERSION')
    if File.exists?(dev_version_file)
      version += File.read(dev_version_file)
    end
    version
  end
end

