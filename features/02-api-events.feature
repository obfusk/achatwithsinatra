Feature: api: events

  Scenario: Welcome message

    When  I reset the server
    When  I listen to `/events` as `devnull`
    And   I wait for listener `devnull`
    Then  The events of `devnull` should be:
      """
      event: welcome
      data: { "id": "SecureRandom#1", "nick": "guest1" }
      """

# Scenario: I say Hello

#   When  I listen to `/events` as `devnull`
#   And   I post JSON to `/say/devnull`:
#     """
#     ...
#     """
#   And   I wait for listener `devnull`
#   Then  The events of `devnull` should be:
#     """
#     event: say
#     data: ...
#     """
