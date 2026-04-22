load test_helper

@test "sort_by_mtime: desc ordering by field 1" {
  input=$'1700\tsess-c\t/a\tm\n2000\tsess-a\t/a\tm\n1800\tsess-b\t/a\tm'
  run bash -c ". '$CX_LITE' && printf '%s' '$input' | sort_by_mtime"
  [ "$status" -eq 0 ]
  first_line="$(printf '%s' "$output" | head -1)"
  [[ "$first_line" == 2000* ]]
  last_line="$(printf '%s' "$output" | tail -1)"
  [[ "$last_line" == 1700* ]]
}
