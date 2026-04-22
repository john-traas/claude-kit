load test_helper

@test "discover_sessions: finds all fixture jsonl files" {
  run bash -c ". '$CX_LITE' && discover_sessions"
  [ "$status" -eq 0 ]
  [ "$(echo "$output" | wc -l | tr -d ' ')" -eq 6 ]
  [[ "$output" == *"sess-001-normal.jsonl"* ]]
  [[ "$output" == *"sess-005-corrupt.jsonl"* ]]
  [[ "$output" == *"sess-006-real.jsonl"* ]]
}

@test "discover_sessions: empty projects dir returns nothing" {
  rm -rf "$HOME/.claude/projects"
  mkdir -p "$HOME/.claude/projects"
  run bash -c ". '$CX_LITE' && discover_sessions"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
