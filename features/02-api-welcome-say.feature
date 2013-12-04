Feature: api: welcome and say

  Scenario: Welcome message

    When  I reset the server
    When  I listen to `/events` as `devnull`
    And   I wait for listener `devnull`
    Then  The events of `devnull` should be:
      """
      event: welcome
      data: { "id": "SecureRandom#1", "nick": "guest1",
              "channel": "devnull" }
      """

  Scenario: I listen, say Hello, listen, say Hello Again

    When  I reset the server
    When  I listen to `/events` as `devnull1`
    And   I post JSON to `/say`:
      """
      { "id": "SecureRandom#1", "message": "Hello" }
      """
    And   I wait for listener `devnull1`
    When  I listen to `/events` as `devnull2`
    And   I post JSON to `/say`:
      """
      { "id": "SecureRandom#1", "message": "Hello Again" }
      """
    And   I wait for listener `devnull2`
    Then  The events of `devnull1` should be:
      """
      event: welcome
      data: { "id": "SecureRandom#1", "nick": "guest1",
              "channel": "devnull" }

      event: say
      data: { "nick": "guest1", "message": "Hello" }
      """
    Then  The events of `devnull2` should be:
      """
      event: welcome
      data: { "id": "SecureRandom#2", "nick": "guest2",
              "channel": "devnull" }

      event: say
      data: { "nick": "guest1", "message": "Hello Again" }
      """
