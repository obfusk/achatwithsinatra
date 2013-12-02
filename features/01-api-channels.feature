Feature: api channels

  Scenario: 2 channels

    When  I reset the server
    And   I listen to `/messages/foo` as `foo`
    And   I listen to `/messages/bar` as `bar`
    And   I wait for listener `foo`
    And   I wait for listener `bar`
    And   I request `/channels`
    Then  The JSON response should be:
      """
      ["bar","foo"]
      """

   Scenario: no channels

    When  I reset the server
    And   I request `/channels`
    Then  The JSON response should be:
      """
      []
      """
