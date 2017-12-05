#!/usr/bin/env bats

@test "smoke" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}
