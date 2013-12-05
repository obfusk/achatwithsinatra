@javascript
Feature: UI

  Scenario: I use the UI to talk to a bot

    When  I reset the server
    And   I go to the chat UI
    And   I set my nick to `felix`
    And   I join `test-talk`
    And   User `bot` (2) joins `test-talk` and says `Hello felix`
    And   I say `Hello bot`
    And   User `bot` stops listening
    Then  I should see UI messages:
      """
        * welcome `guest1`  `devnull`
        * join    `guest1`  `devnull`
        * nick    `guest1`  `felix`
        * join    `felix`   `test-talk`
        * join    `bot`     `test-talk`
        * say     `bot`     `Hello felix`
        * say     `felix`   `Hello bot`
      """
    And   User `bot` should see API messages:
      """
        * welcome `guest2`  `devnull`
        * join    `guest2`  `devnull`
        * nick    `guest2`  `bot`
        * join    `bot`     `test-talk`
        * say     `bot`     `Hello felix`
        * say     `felix`   `Hello bot`
      """
