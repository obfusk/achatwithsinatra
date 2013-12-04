Feature: api: join

  Scenario: I listen, say, join, say

    When  I reset the server
    And   I listen to `/events` as `devnull`
    And   I post JSON to `/say`:
      """
      { "id": "SecureRandom#1", "message": "Hi devnull" }
      """
    And   I post JSON to `/join`:
      """
      { "id": "SecureRandom#1", "channel": "devrandom" }
      """
    And   I post JSON to `/say`:
      """
      { "id": "SecureRandom#1", "message": "Hi devrandom" }
      """
    And   I wait for listener `devnull`
    Then  The events of `devnull` should be:
      """
      event: welcome
      data: { "id": "SecureRandom#1", "nick": "guest1",
              "channel": "devnull" }

      event: join
      data: { "nick": "guest1", "channel": "devnull" }

      event: say
      data: { "nick": "guest1", "message": "Hi devnull" }

      event: join
      data: { "nick": "guest1", "channel": "devrandom" }

      event: say
      data: { "nick": "guest1", "message": "Hi devrandom" }
      """
