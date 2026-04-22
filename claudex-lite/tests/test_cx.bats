load test_helper

_cx() { echo "$CX_LITE_DIR/../cx"; }

@test "cx: --help prints usage" {
  run "$(_cx)" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: cx"* ]]
  [[ "$output" == *"lite"* ]]
  [[ "$output" == *"full"* ]]
}

@test "cx: defaults to claudex-lite when only lite is on PATH" {
  local bin="$BATS_TMPDIR/cx-test-lite-$$-$RANDOM"
  mkdir -p "$bin"
  ln -s "$CX_LITE" "$bin/claudex-lite"
  cd "$PROJ_ALPHA"
  run env PATH="$bin:$PATH" "$(_cx)" pick --print-first
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r uuid cwd <<< "$output"
  [ "$uuid" = "sess-001-normal" ]
  [ "$cwd" = "$PROJ_ALPHA" ]
}

@test "cx: prefers claudex (full) when both tiers are on PATH" {
  local bin="$BATS_TMPDIR/cx-test-full-$$-$RANDOM"
  mkdir -p "$bin"
  cat > "$bin/claudex" <<'STUB'
#!/usr/bin/env bash
echo "FULL-TIER $*"
STUB
  chmod +x "$bin/claudex"
  ln -s "$CX_LITE" "$bin/claudex-lite"
  run env PATH="$bin:$PATH" "$(_cx)" --all
  [ "$status" -eq 0 ]
  [[ "$output" == "FULL-TIER --all" ]]
}

@test "cx: 'lite' subcommand forces lite even when full is available" {
  local bin="$BATS_TMPDIR/cx-test-force-$$-$RANDOM"
  mkdir -p "$bin"
  cat > "$bin/claudex" <<'STUB'
#!/usr/bin/env bash
echo "FULL-TIER should not run"
STUB
  chmod +x "$bin/claudex"
  ln -s "$CX_LITE" "$bin/claudex-lite"
  cd "$PROJ_ALPHA"
  run env PATH="$bin:$PATH" "$(_cx)" lite pick --print-first
  [ "$status" -eq 0 ]
  IFS=$'\t' read -r uuid cwd <<< "$output"
  [ "$uuid" = "sess-001-normal" ]
}

@test "cx: errors when neither tier is installed" {
  local bin="$BATS_TMPDIR/cx-test-none-$$-$RANDOM"
  mkdir -p "$bin"
  ln -s "$(command -v bash)" "$bin/bash"
  run env PATH="$bin" "$(_cx)"
  [ "$status" -ne 0 ]
  [[ "$output" == *"neither"* ]]
}
