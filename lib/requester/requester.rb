require 'rubygems'
require 'ostruct'
require 'httparty'
require 'erb'
require File.dirname(__FILE__) + '/../shared/ssh_tunnel'
require File.expand_path(File.dirname(__FILE__) + '/../shared/testbot')
require File.expand_path(File.dirname(__FILE__) + '/client')
require File.expand_path(File.dirname(__FILE__) + '/console_display')

class Hash
  def symbolize_keys_without_active_support
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
    options
    end
  end
end

module Testbot::Requester
  class Requester
    attr_reader :config

    def initialize(config = {})
      config = config.symbolize_keys_without_active_support
      config[:rsync_path]             ||= Testbot::DEFAULT_SERVER_PATH
      config[:project]                ||= Testbot::DEFAULT_PROJECT
      config[:server_user]            ||= Testbot::DEFAULT_USER
      config[:available_runner_usage] ||= Testbot::DEFAULT_RUNNER_USAGE
      @config = OpenStruct.new(config)
    end

    def run_tests(adapter, dir)
      client = Client.new(config, adapter, self)
      display = ConsoleDisplay.new(self)

      display.empty_line if config.simple_output || config.logging

      unless client.request_run(dir)
        if client.error_type == :no_runners_available
          display.text "No runners available. If you just started a runner, try again. It usually takes a few seconds before they're available."
        else
          display.text "Could not create build, #{client.error_info}"
        end

        return false
      end

      at_exit do
        client.stop_run
      end

      display.empty_line if config.logging

      client.on_new_results do |result|
        if config.simple_output
          display.text result.gsub(/[^\.F]|Finished/, ''), false
        else
          display.text result, false
        end
      end

      display.empty_line if config.simple_output

      summary = client.result_summary
      display.text "\n" + summary if summary

      client.build_successful?
    end

    def self.create_by_config(path)
      Requester.new(YAML.load(ERB.new(File.open(path).read).result))
    end
  end
end
