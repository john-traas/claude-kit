load test_helper

@test "startup: missing fzf prints install hint" {
  local bin="$BATS_TMPDIR/bin-no-fzf-$$-$RANDOM"
  mkdir -p "$bin"
  # Symlink bash so the script's shebang resolves under the stripped PATH.
  ln -s "$(command -v bash)" "$bin/bash"
  run env PATH="$bin" "$CX_LITE" pick
  [ "$status" -ne 0 ]
  [[ "$output" == *"fzf"* ]]
  [[ "$output" == *"install"* ]]
}

@test "startup: missing jq prints install hint" {
  local bin="$BATS_TMPDIR/bin-fzf-no-jq-$$-$RANDOM"
  mkdir -p "$bin"
  ln -s "$(command -v bash)" "$bin/bash"
  # Stub fzf so the check reaches jq. System bin dirs would otherwise
  # supply jq (e.g. /usr/bin/jq on macOS).
  cat > "$bin/fzf" <<'STUB'
#!/usr/bin/env bash
head -1
STUB
  chmod +x "$bin/fzf"
  run env PATH="$bin" "$CX_LITE" pick
  [ "$status" -ne 0 ]
  [[ "$output" == *"jq"* ]]
  [[ "$output" == *"install"* ]]
}

@test "resume: missing cwd exits 1 with hint" {
  run "$CX_LITE" resume sess-001-normal /nonexistent/path
  [ "$status" -eq 1 ]
  [[ "$output" == *"no longer exists"* ]]
}
