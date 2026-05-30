# Browser Mocap Manual Test Checklist (Chrome)

Run through this end-to-end after any change to `index.html`. Target
browser: Chrome stable, webcam, the converted `uk1_outboxer.glb`.

## Setup

- [ ] **0. Boot.** Double-click `index.html`. Page renders without
  console errors. Status bar shows FPS once render loop starts. Left,
  center, right panels visible; bottom status bar visible.

## Model + scene

- [ ] **1. Load model.** Click "Choose File" under Model, pick
  `uk1_outboxer.glb`. Toast "Model loaded" appears. Status shows
  "Bones: <number>. Mapped: 17/17" (or near it; warn if < 15). DevTools
  console lists all bones and which CC5 names were resolved.
- [ ] **2. Scene controls.** Drag with left mouse = orbit. Right mouse
  = pan. Scroll = zoom. Press `S` -> skeleton overlay toggles on/off.
  Click "Axes" -> small XYZ gizmos toggle on the Hips/Chest/Head/arms.
- [ ] **3. Floor reference.** Character feet sit on or very close to
  Y=0 (the green floor cross is visible at origin).

## Webcam + tracking

- [ ] **4. Webcam.** Click "Start Webcam". Browser asks for permission;
  grant it. Live feed appears top-left, 320x240. Within ~5 seconds the
  status bar reads "Tracking: OK" and the dot turns green. Green
  landmark dots overlay your body in the preview.
- [ ] **5. Tracking-lost recovery.** Step out of frame for 3 seconds.
  Status flips to "Tracking: lost (N frames)" with red dot. Step back
  in -> recovers to OK within 1 second.

## Calibration

- [ ] **6. T-pose capture.** Stand in T-pose (arms straight out, palms
  forward). Click "Capture T-Pose (3s)". Status counts up to 3.0s, then
  shows green checkmark. Status bar "Calibrated: Yes". After this,
  standing in T-pose should give a near-rest character pose on screen.
- [ ] **7. Live drive.** Raise left arm forward -> character's
  corresponding arm moves. If it moves wrong (mirrored, rotated 90°),
  go to bone-correction sliders; specifically `LeftUpperArm.z` and
  `RightUpperArm.z` are the usual culprits. Adjust until correct.

## Bone-correction tuning

- [ ] **8. Slider live edit.** Expand "Per-Bone Correction (CC5)".
  Drag `LeftUpperArm.z` slider while watching the character — the arm
  rotation updates per frame (no restart needed).
- [ ] **9. Preset save/load.** Click "Save Preset" -> toast confirms.
  Refresh the page, reload model, recalibrate, click "Load Preset" ->
  sliders restore prior values, character rig is back to your tuned
  state.
- [ ] **10. Console live tuning.** In DevTools:
  `window.boneCorrections.LeftUpperArm.z = 70`. The character updates
  next frame; the slider position does NOT auto-sync (expected — console
  is the source of truth between slider edits).

## Recording + timeline

- [ ] **11. Record + stop.** Click "Start Recording" (button turns red,
  pulses). Throw 3 jabs over ~4 seconds. Click "Stop". Toast shows
  "take_001 saved: ~4.00s, ~N frames". Timeline appears at the bottom
  of the viewer. A new entry appears in the Takes list.
- [ ] **12. Scrub + trim.** Click and drag inside the timeline track ->
  character poses to that frame. Move scrub to just before the first
  jab; press `I` -> green IN marker locks at scrub. Move scrub to just
  after the last jab; press `O` -> red OUT marker locks. The aqua
  region shows what will export. Toggle "Loop trim" + press Space ->
  trimmed region loops on the character.

## QC features

- [ ] **13. Foot HUD + Bone HUD.** Right panel shows live foot Y values
  (should be ~0 when standing); raise a foot -> value goes positive,
  flashes red over 0.05. Bone HUD shows live Euler degrees for the
  9 key bones; a forearm pushed into hyperextension should turn the row
  yellow then red as |angle| crosses 150 / 180.
- [ ] **14. Auto-trim + Despike.** Click "Auto-trim static" on a take
  with idle frames at the start — IN marker should snap forward to
  where motion begins. Click "Despike" — toast reports how many frames
  were smoothed. Both operations update the scrub clip live.

## Export + verify

- [ ] **15. Export + round-trip.** Set the take grade to "B", category
  "Jab". Click "Export Selected". `take_001_Jab_B.glb` downloads.
  Click "Verify Re-load" -> toast confirms `1 clip(s), 17+ tracks,
  ~Xs`. Open the file in Blender or another GLB viewer (or load it
  back via the Compare panel) — animation plays and the character
  performs the jab. Pre-export verification rejects any take with
  zero-duration or single-keyframe tracks (try recording for only
  100 ms to confirm the rejection path).

## Pre-recorded Video mode

- [ ] **16. Mode toggle.** With webcam running, click the "Pre-recorded
  Video" tab at the top of the left panel. Webcam stops (LED off,
  webcam preview hides). Video File panel appears. Status bar reads
  "Mode: Video — (no file)". Click "Live Webcam" — video panel hides,
  webcam panel reappears, status bar back to "Mode: Live Webcam". Click
  "Start Webcam" again; it works.
- [ ] **17. Video file load.** Switch to Video mode. Click "Choose
  File" under Video File and pick one of the IMG_*.MOV files (e.g.
  `Desktop\markerless mocap\Rep1\IMG_0054.MOV`). Within a second or two
  the preview shows the first frame. Video Info shows
  `IMG_0054.MOV<br>1920x1080 · M:SS.SS · ~XXX.X MB`. Status bar shows
  "Mode: Video — IMG_0054.MOV".
- [ ] **18. Playback controls.** Click "Play" — video starts; landmarks
  draw over the preview (green dots), and the character mimics the
  subject. Click "Pause" — video stops; landmarks freeze; FPS stays
  high (render loop still running). Drag scrub bar — video jumps to
  that frame, MediaPipe re-runs, character pose updates. Click "Step
  ▷" — video advances ~1/30s, character pose updates. Switch Speed
  dropdown to 0.25x — playback slows; tracking remains stable.
- [ ] **19. Video T-pose calibration.** Scrub to a frame where the
  subject is approximately in T-pose (or a stable rest pose). Click
  "Capture T-Pose (current frame)". Status counts 0.0 → 3.0s, then
  shows green checkmark. Status bar "Calibrated: Yes". The character's
  pose should now look roughly like the subject's pose when the
  scrubber is parked on a different frame.
- [ ] **20. Record from video.** Scrub to a few seconds before a punch.
  Click "Start Recording" — button turns red and pulses. Click "Play"
  on the video. Watch the character mimic the punch. Click "Stop" (or
  let the video reach the end — recording should auto-stop). Toast
  reads "take_NNN saved: X.XXs, ~N frames". A take entry appears.
  Important: the clip duration should match the *video-time* of the
  recorded segment, not wall-clock. So a 5-second punch recorded at
  0.25x playback produces a 5-second animation, not a 20-second one.
- [ ] **21. Export from video take.** Set grade B, category Jab. Click
  "Export Selected". `take_NNN_Jab_B.glb` downloads. Click "Verify
  Re-load" — toast confirms 1 clip, 17+ tracks, ~5s duration.
- [ ] **22. Re-pick video file.** With one video loaded, click "Choose
  File" again and pick a different `.MOV`. The previous file's object
  URL is revoked (no memory leak); the new file loads in its place.
  Status bar updates to the new filename. Old take is preserved in the
  Takes list.
- [ ] **23. Mode switch with active video.** Load a video, click Play,
  let it run a few seconds, then switch back to Live Webcam. Video
  pauses cleanly; MediaPipe loop stops; switching back to Video
  picks up where it left off (file still loaded, scrub position
  preserved).

## Bonus / regression spot-checks

- [ ] Multiple takes: record 3 takes in a row, rename them, grade one
  as "Skip", click "Export Selected" -> only 2 GLBs download.
- [ ] Refresh the page mid-session — no exception thrown.
- [ ] FPS dot stays green (>30) on a decent laptop with character
  loaded and webcam streaming.
- [ ] Large file handling: load a ~1.5 GB MOV; browser memory stays
  reasonable (Chrome streams the file rather than loading it whole).
  Scrubbing remains responsive.
