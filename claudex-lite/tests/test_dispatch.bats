load test_helper

@test "dispatch: --help prints usage" {
  run "$CX_LITE" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: claudex-lite"* ]]
}
