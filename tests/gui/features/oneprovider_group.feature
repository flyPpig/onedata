Feature: Oneprovider Group functionality
  Various operations on groups

  # assuming there is user1 login
  # assuming there is p1 provider
  Background:
    Given user opens a Onezone URL in a web browser
    And user clicks on the "indigo" login button
    And user clicks on the "user1" link
    And user expands the "go to your files" Onezone sidebar panel
    And user clicks on the "p1" provider in Onezone providers sidebar panel
    And user clicks on the "Go to your files" button in provider popup
    And user clicks on the "groups" tab in main menu

  Scenario: User can add new group
    Given valid name string
    When user clicks on the "Create" button in sidebar panel
    And user should see that "Create a new group" input box is active
    And user types given name on keyboard
    And user presses enter on keyboard
    Then user should see that the new group appears on the list

  # assuming there is group1
  Scenario: User can invite other user
    Given there is a "group1" item on a sidebar list
    When user clicks a settings icon displayed for "group1" list item
    And user should see a settings dropdown menu for "group1" list item
    And user clicks on the "invite user" item in current settings dropdown
    And user should see that "Invite user to the group" token box is active
    Then user should see non-empty token in active modal

  # assuming there is group1
  Scenario: User can invite group
    Given there is a "group1" item on a sidebar list
    When user clicks a settings icon displayed for "group1" list item
    And user should see a settings dropdown menu for "group1" list item
    And user clicks on the "invite group" item in current settings dropdown
    And user should see that "Invite group to the group" token box is active
    Then user should see non-empty token in active modal

  # assuming there is group1
  Scenario: User can request space creation
    Given there is a "group1" item on a sidebar list
    When user clicks a settings icon displayed for "group1" list item
    And user should see a settings dropdown menu for "group1" list item
    And user clicks on the "request space creation" item in current settings dropdown
    And user should see that "Request space creation for the group" token box is active
    Then user should see non-empty token in active modal

  # assuming there is group1
  Scenario: User can try to join space with incorrect token
    Given there is a "group1" item on a sidebar list
    When user clicks a settings icon displayed for "group1" list item
    And user should see a settings dropdown menu for "group1" list item
    And user clicks on the "join space" item in current settings dropdown
    And user should see that "Join a space" input box is active
    And user types "helloworld" on keyboard
    And user presses enter on keyboard
    Then user sees an error notify with text matching to: .*join.*group1.*space.*

  # assuming there is group1
  Scenario: User can try to join as subgroup with incorrect token
    Given there is a "group1" item on a sidebar list
    When user clicks a settings icon displayed for "group1" list item
    And user should see a settings dropdown menu for "group1" list item
    And user clicks on the "join as subgroup" item in current settings dropdown
    And user should see that "Join a group to group" input box is active
    And user types "helloworld" on keyboard
    And user presses enter on keyboard
    Then user sees an error notify with text matching to: .*join.*group1.*subgroup.*

  Scenario: Try join to group with incorrect token
    When user clicks on the "Join" button in sidebar panel
    And user should see that "Join a group" input box is active
    And user types "helloworld" on keyboard
    And user presses enter on keyboard
    Then user sees an error notify with text matching to: .*Failed.*join.*group.*


#  Scenario: Rename group
#    Given user has new name for group
#    When user clicks on the "groups" provider in Oneprovider providers sidebar panel
#    # group1 is defined in json
#    And user clicks on the settings button for "group1"
#    And user clicks on the "RENAME" in current settings dropdown
#    And user should see that rename input box is active
#    And user types new group name on keyboard
#    And user presses enter on keyboard
#    Then user should see popup with information about name change
#    And user should see, that the new name replaced old one on the list
