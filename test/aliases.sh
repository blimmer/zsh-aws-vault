#!/usr/bin/env bats

@test "smoke" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "stubs" {
  stub date \
    "${_DATE_ARGS} : echo 1460967598.184561556" \

    run get_timestamp
    assert_success
    assert_output 1460967598184
}
