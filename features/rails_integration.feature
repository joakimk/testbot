Feature: Rails integration

  Scenario Outline: Adding testbot to a rails project
    Given I have a rails <rails_version> application
    And I add testbot
    Then the testbot rake tasks are present
    And I run "<generate_config_command>"
    Then there is a "lib/tasks/testbot.rake" file
    And there is a "config/testbot.yml" file
    And the "config/testbot.yml" file contains "server_host: 192.168.1.55"

   Examples:
     | rails_version | generate_config_command                        |
     | 3.0.3         | rails g testbot --connect 192.168.1.55         |
     | 2.3.10        | script/generate testbot --connect 192.168.1.55 |

  Scenario: Using testbot with Rails 3 and RSpec 2
    Given I have a rails 3.0.3 application
    And I add testbot
    And I add rspec 2 and some specs
    And I have a testbot network setup
    Then I can successfully run "rake testbot:spec"
