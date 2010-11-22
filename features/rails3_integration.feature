Feature: Rails 3 integration

  Scenario: Adding testbot as a gem dependency and generating config
    Given I have a rails 3 application
    And I add testbot as a gem dependency
    And I run "rails g testbot --connect 192.168.1.55"

