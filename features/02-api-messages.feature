Feature: api messages

  Scenario: say Hello

    When  I listen to `/messages/foo` as `foo`
    And   I post JSON to `/say/foo`:
      """
      { "message": "Hello" }
      """
    And   I wait for listener `foo`
    Then  The messages of `foo` should be:
      """
      event: say
      data: {"message":"Hello"}


      """
