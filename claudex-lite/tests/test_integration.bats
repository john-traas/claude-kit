load test_helper

@test "scan: produces TSV for all fixture sessions" {
  run bash -c "export CX_LITE_SELF='$CX_LITE'; . '$CX_LITE' && scan_sessions"
  [ "$status" -eq 0 ]
  lines="$(printf '%s\n' "$output" | wc -l | tr -d ' ')"
  [ "$lines" -eq 6 ]
  [[ "$output" == *"sess-001-normal"* ]]
  [[ "$output" == *"$PROJ_ALPHA"* ]]
}

@test "scan: newest first after sort" {
  run bash -c "export CX_LITE_SELF='$CX_LITE'; . '$CX_LITE' && scan_sessions | sort_by_mtime"
  [ "$status" -eq 0 ]
  first_uuid="$(printf '%s\n' "$output" | head -1 | cut -f2)"
  [ "$first_uuid" = "sess-001-normal" ]
}

@test "pick: prints uuid<TAB>cwd via --print-first to first match" {
  cd "$PROJ_ALPHA"
  run bash -c "export CX_LITE_SELF='$CX_LITE'; '$CX_LITE' pick --print-first"
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r uuid cwd <<< "$output"
  [ "$uuid" = "sess-001-normal" ]
  [ "$cwd" = "$PROJ_ALPHA" ]
}

@test "pick --all --print-first: returns the newest across all cwds" {
  # cwd does not match any fixture project; --all broadens scope.
  cd "$CX_TEST_ROOT"
  run bash -c "export CX_LITE_SELF='$CX_LITE'; '$CX_LITE' pick --all --print-first"
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r uuid cwd <<< "$output"
  [ "$uuid" = "sess-001-normal" ]
  [ "$cwd" = "$PROJ_ALPHA" ]
}

@test "pick (no --all) from non-project cwd: warns, exits 0" {
  cd "$CX_TEST_ROOT"
  run bash -c "export CX_LITE_SELF='$CX_LITE'; '$CX_LITE' pick --print-first"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no sessions"* ]]
}
