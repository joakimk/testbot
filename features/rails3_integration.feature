Feature: Rails 3 integration

  Scenario: Adding testbot as a gem dependency and generating config
    Given I have a rails 3 application
    And I add testbot as a gem dependency
    And I run "rails g testbot --connect 192.168.1.55"
    Then there is a "lib/tasks/testbot.rake" file
    And there is a "config/testbot.yml" file
    And the "config/testbot.yml" file contains "server_host: 192.168.1.55"

