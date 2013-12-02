Feature: api

  Scenario: 2 channels

    When  I reset the server
    When  I request `/messages/foo` asynchronously
    When  I request `/messages/bar` asynchronously
    When  I request `/channels`
    Then  The JSON response should be:
      """
      ["bar","foo"]
      """

   Scenario: no channels

    When  I reset the server
    When  I request `/channels`
    Then  The JSON response should be:
      """
      []
      """
