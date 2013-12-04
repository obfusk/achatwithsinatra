Feature: api: nick and me

  Scenario: I listen, me Waves

    When  I reset the server
    When  I listen to `/events` as `devnull`
    And   I post JSON to `/me`:
      """
      { "id": "SecureRandom#1", "message": "Waves" }
      """
    And   I wait for listener `devnull`
    Then  The events of `devnull` should be:
      """
      event: welcome
      data: { "id": "SecureRandom#1", "nick": "guest1",
              "channel": "devnull" }

      event: me
      data: { "nick": "guest1", "message": "Waves" }
      """

  Scenario: I listen, change my nick, say Hello

    When  I reset the server
    When  I listen to `/events` as `devnull`
    And   I post JSON to `/nick`:
      """
      { "id": "SecureRandom#1", "nick": "felix" }
      """
    And   I post JSON to `/say`:
      """
      { "id": "SecureRandom#1", "message": "Hello" }
      """
    And   I wait for listener `devnull`
    Then  The events of `devnull` should be:
      """
      event: welcome
      data: { "id": "SecureRandom#1", "nick": "guest1",
              "channel": "devnull" }

      event: nick
      data: { "from": "guest1", "to": "felix" }

      event: say
      data: { "nick": "felix", "message": "Hello" }
      """
