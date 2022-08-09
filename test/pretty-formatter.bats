#!/usr/bin/env bats

setup() {
  load test_helper
  fixtures bats
}

@test "Timing printout shows milliseconds" {
    format_example_stream() {
        bats-format-pretty -T  <<HERE
1..1
suite /test/path
begin 1 test
ok 1 test in 123ms
HERE
    }
    run format_example_stream
    echo "$output"
    [[ "${lines[1]}" == *'[123]'* ]]
}

@test "pretty formatter summary is colorized red on failure" {
  bats_require_minimum_version 1.5.0
  run -1 bats --pretty "$FIXTURE_ROOT/failing.bats"
  
  [ "${lines[4]}" == $'\033[0m\033[31;1m' ] # TODO: avoid checking for the leading reset too
  [ "${lines[5]}" == '1 test, 1 failure' ]
  [ "${lines[6]}" == $'\033[0m' ]
}

@test "pretty formatter summary is colorized green on success" {
  bats_require_minimum_version 1.5.0
  run -0 bats --pretty "$FIXTURE_ROOT/passing.bats"

  [ "${lines[2]}" == $'\033[0m\033[32;1m' ] # TODO: avoid checking for the leading reset too
  [ "${lines[3]}" == '1 test, 0 failures' ]
  [ "${lines[4]}" == $'\033[0m' ]
}

@test "Mixing timing and timeout" {
  format_example_stream() {
    bats-format-pretty -T  <<HERE
1..2
suite /test/path
begin 1 test timing=1, timeout=0
ok 1 test timing=1, timeout=0 in 123ms
begin 2 test timing=1, timeout=1
not ok 2 test timing=1, timeout=1 in 456ms # timeout after 0s
HERE
  }
  run format_example_stream
  # black text, green timing
  [[ "${lines[1]}" == *$'\x1b[2G\x1b[1G ✓ test timing=1, timeout=0\x1b[32;22m [123]'* ]]
  # red bold text, green timing
  [[ "${lines[2]}" == *$'\x1b[2G\x1b[33;1m\x1b[1G ✗ test timing=1, timeout=1\x1b[32;22m [456 (timeout: 0s)]'* ]]
  [[ "${lines[4]}" == *$'2 tests, 0 failures, 1 timed out in 0 seconds'* ]]

format_example_stream() {
    bats-format-pretty  <<HERE
1..1
suite /test/path
begin 1 test timing=0, timeout=1
not ok 1 test timing=0, timeout=1 # timeout after 0s
# timeout text
HERE
  }
  run format_example_stream
  # yellow bold text, green timing
  [[ "${lines[1]}" == *$'\x1b[2G\x1b[33;1m\x1b[1G ✗ test timing=0, timeout=1\x1b[32;22m [timeout: 0s]'* ]]
  [[ "${lines[2]}" == *$'\x1b[0m\x1b[33;22m   timeout text'* ]]
  [[ "${lines[4]}" == *$'1 test, 0 failures, 1 timed out'* ]]
}