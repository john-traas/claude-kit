load test_helper

@test "filter_cwd: keeps only exact matches" {
  input=$'1000\tsess-a\t/Users/me/alpha\tmsg\n2000\tsess-b\t/Users/me/beta\tmsg'
  run bash -c ". '$CX_LITE' && printf '%s' '$input' | filter_cwd '/Users/me/alpha'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"sess-a"* ]]
  [[ "$output" != *"sess-b"* ]]
}

@test "filter_cwd: empty input yields empty output" {
  run bash -c ". '$CX_LITE' && printf '' | filter_cwd '/Users/me/alpha'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "filter_cwd: no matches yields empty output, exit 0" {
  input=$'1000\tsess-a\t/other/path\tmsg'
  run bash -c ". '$CX_LITE' && printf '%s' '$input' | filter_cwd '/Users/me/alpha'"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
