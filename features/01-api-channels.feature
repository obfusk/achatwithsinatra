Feature: api: channels

  Scenario: I open 2 channels

    When  I reset the server
    And   I listen to `/events/foo` as `foo`
    And   I listen to `/events/bar` as `bar`
    And   I wait for listener `foo`
    And   I wait for listener `bar`
    And   I request `/channels`
    Then  The JSON response should be:
      """
      [ "bar", "foo" ]
      """

   Scenario: I don't open any channels

    When  I reset the server
    And   I request `/channels`
    Then  The JSON response should be:
      """
      []
      """

  Scenario: I open the default channel (devnull)

    When  I reset the server
    And   I listen to `/events` as `devnull`
    And   I wait for listener `devnull`
    And   I request `/channels`
    Then  The JSON response should be:
      """
      [ "devnull" ]
      """
