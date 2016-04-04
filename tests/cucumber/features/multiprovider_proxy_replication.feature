Feature: Multiprovider_proxy_replication

  Background:
    Given environment is defined in multiprovider_proxy_env.json
    And storage directories are empty
    And environment is up
    And [u1, u2] start oneclients [client1, client2] in
      [/home/u1/onedata, /home/u2/onedata] on client_hosts
      [client_host_1, client_host_2] respectively,
      using [token, token]

  Scenario: Create files and see them on external provider
    When u2 waits 5 seconds on client2
    And u1 creates regular files [file1, file2, file3] on client1
    Then u2 waits 10 seconds on client2 # wait for events handling
    And u2 sees [file1, file2, file3] in . on client2

  Scenario: Create empty file and read it on external provider
    When u2 waits 5 seconds on client2
    And u1 creates regular files [file] on client1
    Then u2 waits 10 seconds on client2 # wait for events handling
    And u2 reads "" from file on client2

  Scenario: Write to file and check size on remote provider
    When u2 waits 5 seconds on client2
    And u1 creates regular files [file] on client1
    And u1 writes "TEST TEXT ONEDATA" to file1 on client1
    Then u2 waits 10 seconds on client2 # wait for events handling
    And size of u2's file1 is 17 bytes on client2

  Scenario: Write to file and read on remote provider
    When u2 waits 5 seconds on client2
    And u1 creates regular files [file1] on client1
    And u1 writes "TEST TEXT ONEDATA" to file1 on client1
    Then u2 waits 10 seconds on client2 # wait for events handling
    And u2 reads "TEST TEXT ONEDATA" from file1 on client2

  Scenario: Big file transfer with MD5 check
    When u2 waits 5 seconds on client2
    And u1 creates regular files [file1] on client1
    And u1 writes 16 MB of random characters to file1 on client1 and saves MD5
    Then u2 waits 10 seconds on client2 # wait for events handling
    And u2 checks MD5 of file1 on client2

  Scenario: Remote file override
    When u2 waits 5 seconds on client2
    And u1 creates regular files [file1] on client1
    And u1 writes "123456789" to file1 on client1
    And u2 waits 10 seconds on client2 # wait for events handling
    And u2 writes "abcd" to file1 on client2
    Then u1 waits 10 seconds on client1 # wait for events handling
    And u1 reads "abcd" from file1 on client1

  Scenario: Remote file removal
    When u2 waits 5 seconds on client2
    And u1 creates regular files [file1] on client1
    And u1 writes "123456789" to file1 on client1
    And u1 waits 10 seconds on client1 # wait for events handling
    And u1 deletes files [file1] on client1
    And u1 doesn't see [file1] in . on client1
    Then u2 waits 10 seconds on client2 # wait for events handling
    And u2 doesn't see [file1] in . on client2

  Scenario: Sequential appends
    When u2 waits 5 seconds on client2
    And u1 creates regular files [file1] on client1
    And u1 writes "a" to file1 on client1
    And u2 waits 10 seconds on client2 # wait for events handling
    And u2 appends "b" to file1 on client2
    And u1 waits 10 seconds on client1 # wait for events handling
    And u1 appends "c" to file1 on client1
    Then u1 waits 10 seconds on client1 # wait for events handling
    And u1 reads "abc" from file1 on client1
    And u2 reads "abc" from file1 on client2

  Scenario: Conflict on disjoint blocks
    When u2 waits 5 seconds on client2
    And u1 creates regular files [file1] on client1
    And u2 writes "defg" at offset 3 to file1 on client2
    And u1 writes "abc" at offset 0 to file1 on client1
    Then u1 waits 10 seconds on client1 # wait for events handling
    And u1 reads "abcdefg" from file1 on client1
    And u2 reads "abcdefg" from file1 on client2