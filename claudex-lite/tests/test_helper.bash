# tests/test_helper.bash — shared setup for all .bats files
#
# Fixtures are generated dynamically per-test under a dotless temp root,
# so Claude's lossy cwd encoding (slash→dash, dot→dash) round-trips
# cleanly. Static fixtures committed to the repo cannot do this because
# macOS `mktemp -d` paths contain `tmp.XXXX` (a dot).

setup() {
  export CX_LITE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd -P)"
  export CX_LITE="$CX_LITE_DIR/claudex-lite"

  # Test root must contain neither '.' nor '-' in any directory component
  # so Claude's lossy encoding ('/'→'-', '.'→'-') round-trips. Using
  # /tmp (which is /private/tmp on macOS, /tmp on Linux — both clean)
  # with a dashless/dotless suffix. The realpath is verified below.
  export CX_TEST_ROOT="/tmp/claudexlitetest${$}x${RANDOM}"
  mkdir -p "$CX_TEST_ROOT"
  local real_root; real_root="$(cd "$CX_TEST_ROOT" && pwd -P)"
  case "$real_root" in
    *.*|*-*) echo "test root not roundtrippable: $real_root" >&2; return 1 ;;
  esac

  export ORIGINAL_HOME="$HOME"
  export HOME="$CX_TEST_ROOT/home"
  mkdir -p "$HOME/.claude/projects"

  # Real project dirs under the test root; decoded cwds from fixtures
  # must match these so filter_cwd / resume work end-to-end.
  mkdir -p "$CX_TEST_ROOT/projects/alpha"
  mkdir -p "$CX_TEST_ROOT/projects/beta"
  mkdir -p "$CX_TEST_ROOT/projects/unicode"
  mkdir -p "$CX_TEST_ROOT/projects/corrupt"
  # Dashed directory name — decode_cwd cannot roundtrip this, so this
  # fixture exercises the jsonl-cwd-field path in extract_cwd.
  mkdir -p "$CX_TEST_ROOT/projects/real-shape"
  export PROJ_ALPHA="$(cd "$CX_TEST_ROOT/projects/alpha" && pwd -P)"
  export PROJ_BETA="$(cd "$CX_TEST_ROOT/projects/beta" && pwd -P)"
  export PROJ_UNICODE="$(cd "$CX_TEST_ROOT/projects/unicode" && pwd -P)"
  export PROJ_CORRUPT="$(cd "$CX_TEST_ROOT/projects/corrupt" && pwd -P)"
  export PROJ_REAL="$(cd "$CX_TEST_ROOT/projects/real-shape" && pwd -P)"

  local enc_alpha enc_beta enc_unicode enc_corrupt enc_real
  enc_alpha="$(_th_encode_cwd "$PROJ_ALPHA")"
  enc_beta="$(_th_encode_cwd "$PROJ_BETA")"
  enc_unicode="$(_th_encode_cwd "$PROJ_UNICODE")"
  enc_corrupt="$(_th_encode_cwd "$PROJ_CORRUPT")"
  enc_real="$(_th_encode_cwd "$PROJ_REAL")"

  mkdir -p "$HOME/.claude/projects/$enc_alpha"
  mkdir -p "$HOME/.claude/projects/$enc_beta"
  mkdir -p "$HOME/.claude/projects/$enc_unicode"
  mkdir -p "$HOME/.claude/projects/$enc_corrupt"
  mkdir -p "$HOME/.claude/projects/$enc_real"

  cat > "$HOME/.claude/projects/$enc_alpha/sess-001-normal.jsonl" <<'EOF'
{"type":"permission-mode","permissionMode":"default","sessionId":"sess-001-normal"}
{"type":"file-history-snapshot","sessionId":"sess-001-normal"}
{"type":"user","role":"user","content":"Hello alpha project, let's refactor the auth module"}
{"type":"assistant","role":"assistant","content":"Okay, let's look at the auth module first."}
{"type":"user","role":"user","content":"Show me the login flow"}
{"type":"assistant","role":"assistant","content":"Here is the login flow..."}
EOF

  cat > "$HOME/.claude/projects/$enc_alpha/sess-002-short.jsonl" <<'EOF'
{"type":"permission-mode","permissionMode":"default","sessionId":"sess-002-short"}
{"type":"user","role":"user","content":"Short question: what is 2+2?"}
{"type":"assistant","role":"assistant","content":"4"}
EOF

  cat > "$HOME/.claude/projects/$enc_beta/sess-003-normal.jsonl" <<'EOF'
{"type":"permission-mode","permissionMode":"default","sessionId":"sess-003-normal"}
{"type":"user","role":"user","content":"Beta project: investigating the caching layer bug reported in issue 42"}
{"type":"assistant","role":"assistant","content":"Let me read issue 42..."}
{"type":"user","role":"user","content":"Proceed"}
{"type":"assistant","role":"assistant","content":"Done."}
EOF

  cat > "$HOME/.claude/projects/$enc_unicode/sess-004-unicode.jsonl" <<'EOF'
{"type":"permission-mode","permissionMode":"default","sessionId":"sess-004-unicode"}
{"type":"user","role":"user","content":"Unicode test: café crêpe brûlée 日本語テスト 🎉 — this message is intentionally long enough to exceed the 120-char display truncation limit for verification."}
{"type":"assistant","role":"assistant","content":"Reply."}
EOF

  # Corrupt fixture: user line is valid; a later metadata line is broken.
  # extract_metadata should still return the valid user message.
  cat > "$HOME/.claude/projects/$enc_corrupt/sess-005-corrupt.jsonl" <<'EOF'
{"type":"permission-mode","permissionMode":"default","sessionId":"sess-005-corrupt"}
{"type":"file-history-snapshot","sessionId":"sess-005-corrupt"}
{"type":"user","role":"user","content":"Starts fine, then gets corrupt"}
{"this-line-is-broken": "oh no"
EOF

  # Real Claude shape: .message.content is an array; tool-result lines
  # are skipped; cwd, custom-title, gitBranch, version and timestamps
  # are embedded so the one-pass extractor surfaces them all. Unquoted
  # heredoc so $PROJ_REAL expands.
  cat > "$HOME/.claude/projects/$enc_real/sess-006-real.jsonl" <<EOF
{"type":"custom-title","customTitle":"Real session title","sessionId":"sess-006-real"}
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Real Claude shape: hello from a project with dashes"}]},"cwd":"$PROJ_REAL","sessionId":"sess-006-real","gitBranch":"feat/real-shape","version":"2.1.109","timestamp":"2026-04-20T10:00:00Z"}
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Got it."}]},"cwd":"$PROJ_REAL","gitBranch":"feat/real-shape","version":"2.1.109","timestamp":"2026-04-20T10:05:00Z"}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"some output","tool_use_id":"abc"}]},"cwd":"$PROJ_REAL","gitBranch":"feat/real-shape","timestamp":"2026-04-20T10:10:00Z"}
{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Second real message"}]},"cwd":"$PROJ_REAL","gitBranch":"feat/real-shape","timestamp":"2026-04-20T10:30:00Z"}
EOF

  # Deterministic mtimes, newest first
  touch -t 202604210300 "$HOME/.claude/projects/$enc_alpha/sess-001-normal.jsonl"
  touch -t 202604210255 "$HOME/.claude/projects/$enc_alpha/sess-002-short.jsonl"
  touch -t 202604210250 "$HOME/.claude/projects/$enc_beta/sess-003-normal.jsonl"
  touch -t 202604210245 "$HOME/.claude/projects/$enc_unicode/sess-004-unicode.jsonl"
  touch -t 202604210240 "$HOME/.claude/projects/$enc_corrupt/sess-005-corrupt.jsonl"
  touch -t 202604210235 "$HOME/.claude/projects/$enc_real/sess-006-real.jsonl"
}

teardown() {
  export HOME="$ORIGINAL_HOME"
  rm -rf "$CX_TEST_ROOT"
}

# _th_encode_cwd: realpath then apply Claude's encoding (/→-, .→-).
# Used only by this helper to place fixtures under correctly-named dirs.
_th_encode_cwd() {
  local p; p="$(cd "$1" && pwd -P)"
  p="${p//./-}"
  p="${p//\//-}"
  printf '%s' "$p"
}
