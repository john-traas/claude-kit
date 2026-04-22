load test_helper

@test "preview: renders project, session, turns and first/last user message" {
  run "$CX_LITE" preview sess-001-normal
  [ "$status" -eq 0 ]
  [[ "$output" == *"Project:"* ]]
  [[ "$output" == *"$PROJ_ALPHA"* ]]
  [[ "$output" == *"[alpha]"* ]]
  [[ "$output" == *"Session:"* ]]
  [[ "$output" == *"sess-001-normal"* ]]
  [[ "$output" == *"Turns:"* ]]
  [[ "$output" == *"user"* ]]
  [[ "$output" == *"assistant"* ]]
  [[ "$output" == *"Hello alpha project"* ]]
}

@test "preview: real-shape session includes title, branch, version, duration" {
  run "$CX_LITE" preview sess-006-real
  [ "$status" -eq 0 ]
  [[ "$output" == *"Title:"* ]]
  [[ "$output" == *"Real session title"* ]]
  [[ "$output" == *"Branch:"* ]]
  [[ "$output" == *"feat/real-shape"* ]]
  [[ "$output" == *"Version:"* ]]
  [[ "$output" == *"2.1.109"* ]]
  [[ "$output" == *"Started:"* ]]
  [[ "$output" == *"Duration:"* ]]
  # 10:00 → 10:30 spans 30 minutes in the fixture.
  [[ "$output" == *"30m"* ]]
  [[ "$output" == *"First user message:"* ]]
  [[ "$output" == *"Real Claude shape"* ]]
  [[ "$output" == *"Last user message:"* ]]
  [[ "$output" == *"Second real message"* ]]
}

@test "preview: omits Title/Branch/Version lines when fixture has none" {
  run "$CX_LITE" preview sess-001-normal
  [ "$status" -eq 0 ]
  [[ "$output" != *"Title:"* ]]
  [[ "$output" != *"Branch:"* ]]
  [[ "$output" != *"Version:"* ]]
}

@test "preview: unknown uuid prints error and exits 1" {
  run "$CX_LITE" preview nonexistent-uuid
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
}
