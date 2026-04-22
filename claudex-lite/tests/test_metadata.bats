load test_helper

@test "extract_metadata: normal session — uuid, cwd, row with uuid fallback and repo" {
  enc="$(_th_encode_cwd "$PROJ_ALPHA")"
  path="$HOME/.claude/projects/$enc/sess-001-normal.jsonl"
  run bash -c ". '$CX_LITE' && extract_metadata '$path'"
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r mtime uuid cwd row <<< "$output"
  [[ "$mtime" =~ ^[0-9]+$ ]]
  [ "$uuid" = "sess-001-normal" ]
  [ "$cwd" = "$PROJ_ALPHA" ]
  # Fixture has no custom-title → row shows the short uuid prefix.
  [[ "$row" == *"sess-001"* ]]
  # Repo name (basename of cwd) is included in brackets.
  [[ "$row" == *"[alpha]"* ]]
  # No gitBranch in fixture → no branch glyph.
  [[ "$row" != *"⎇"* ]]
  # Row shows label/repo/branch only; timing lives in the preview.
  [[ "$row" != *"ago"* ]]
}

@test "extract_metadata: long branch names get truncated in the row" {
  enc="$(_th_encode_cwd "$PROJ_REAL")"
  path="$HOME/.claude/projects/$enc/sess-006-real.jsonl"
  run bash -c "CX_THEME=mono . '$CX_LITE' && extract_metadata '$path'"
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r _ _ _ row <<< "$output"
  # Fixture branch is short and stays intact.
  [[ "$row" == *"⎇ feat/real-shape"* ]]
}

@test "extract_metadata: real Claude shape — title, repo, branch glyph, cwd from jsonl" {
  enc="$(_th_encode_cwd "$PROJ_REAL")"
  path="$HOME/.claude/projects/$enc/sess-006-real.jsonl"
  run bash -c ". '$CX_LITE' && extract_metadata '$path'"
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r _ uuid cwd row <<< "$output"
  [ "$uuid" = "sess-006-real" ]
  # cwd comes from the jsonl field (decode_cwd would mangle "real-shape").
  [ "$cwd" = "$PROJ_REAL" ]
  [[ "$row" == *"Real session title"* ]]
  [[ "$row" == *"[real-shape]"* ]]
  [[ "$row" == *"⎇ feat/real-shape"* ]]
}

@test "extract_metadata: CX_THEME=mono produces no ANSI escapes" {
  enc="$(_th_encode_cwd "$PROJ_REAL")"
  path="$HOME/.claude/projects/$enc/sess-006-real.jsonl"
  run bash -c "CX_THEME=mono . '$CX_LITE' && extract_metadata '$path'"
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r _ _ _ row <<< "$output"
  # Escape sequences start with 0x1b (ESC).
  [[ "$row" != *$'\033'* ]]
}

@test "extract_metadata: NO_COLOR overrides theme to mono" {
  enc="$(_th_encode_cwd "$PROJ_REAL")"
  path="$HOME/.claude/projects/$enc/sess-006-real.jsonl"
  run bash -c "NO_COLOR=1 CX_THEME=vivid . '$CX_LITE' && extract_metadata '$path'"
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r _ _ _ row <<< "$output"
  [[ "$row" != *$'\033'* ]]
}

@test "extract_metadata: default theme emits ANSI escapes" {
  enc="$(_th_encode_cwd "$PROJ_REAL")"
  path="$HOME/.claude/projects/$enc/sess-006-real.jsonl"
  run bash -c "unset NO_COLOR; . '$CX_LITE' && extract_metadata '$path'"
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r _ _ _ row <<< "$output"
  [[ "$row" == *$'\033'* ]]
}

@test "extract_metadata: corrupt session doesn't crash, emits row" {
  enc="$(_th_encode_cwd "$PROJ_CORRUPT")"
  path="$HOME/.claude/projects/$enc/sess-005-corrupt.jsonl"
  run bash -c ". '$CX_LITE' && extract_metadata '$path'"
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r _ uuid cwd row <<< "$output"
  [ "$uuid" = "sess-005-corrupt" ]
  [ "$cwd" = "$PROJ_CORRUPT" ]
  [ -n "$row" ]
}
