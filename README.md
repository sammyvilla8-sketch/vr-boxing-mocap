# VR Boxing Browser Mocap (CC5 Retarget + Recording + QC)

A self-contained, double-clickable HTML tool for capturing webcam motion
(MediaPipe Holistic + KalidoKit), driving a Reallusion CC5 character with
live per-bone correction quaternions, recording AnimationClips, scrubbing
+ trimming, and exporting GLB with embedded animation.

## Two entry points

- **`index.html`** — the original desktop version. Mouse + keyboard, 3-column layout,
  auto-loads `uk1_outboxer.glb` from the same folder.
- **`ipad.html`** — touch-optimised version for iPad / phone. Big record button,
  back-camera default for tripod use, Web Share API export to iOS share sheet,
  on-screen stick-figure mode buttons (no keyboard hotkeys), responsive layout.
  Same retargeting math under the hood.

Both ship to the same GitHub Pages site:
- Desktop: `https://sammyvilla8-sketch.github.io/vr-boxing-mocap/`
- iPad:    `https://sammyvilla8-sketch.github.io/vr-boxing-mocap/ipad.html`

Built for fast interactive iteration after a weekend of TALOS / CMU /
MediaPipe+ARP / MediaPipe-v2 pipeline failures. The point of this tool is
hot-reload of bone-correction Eulers via on-screen sliders and the
DevTools console.

## UK1 character: served from the repo + cached in IndexedDB

`uk1_outboxer.glb` (~67 MB after Draco compression — well under GitHub's
100 MB file limit) is committed to the repo and served by GitHub Pages
from the same origin as `index.html` / `ipad.html`. This avoids the
CORS issue that GitHub Release assets hit: release URLs don't send
`Access-Control-Allow-Origin`, so `fetch()` from the Pages site is
blocked even though the file is publicly downloadable in a browser tab.

On first load both HTMLs stream-download `./uk1_outboxer.glb` and stash
the blob in **IndexedDB** under the key `uk1_glb_v1` (database
`vr_boxing_mocap_cache`). Subsequent visits on the same device hit the
cache and load instantly. The download UI shows percent + MB / MB
during the one-time fetch with the message "First-time download.
Cached after this — stays available offline."

The desktop launcher (`file://`) hands the local path directly to
`GLTFLoader` rather than going through `fetch()` — works instantly with
no network, same as before.

Clear the cache from the **Clear UK1 cache** button in the Model panel
(desktop) or Character card (iPad), or from the console:
`await window.clearUK1Cache(); location.reload();`

## Launching

### ONE-CLICK MODE (the recommended way)

Double-click `VR Boxing Mocap Tool.bat` on your Desktop. Chrome opens in
a fresh window pointed at this tool, with `uk1_outboxer.glb` already
auto-loaded and the right Chrome flags (`--allow-file-access-from-files`)
and a cache-bust query string so reloads always pick up the latest
`index.html`.

The GLB next to `index.html` (`uk1_outboxer.glb`) is what gets
auto-loaded. Replace that file (keep the name) to change the default
character — the tool will pick up whatever GLB sits there on next launch.

To re-install the Desktop shortcut on a new machine, copy
`LAUNCH_MOCAP.bat` (in this folder) to your Desktop and rename to
`VR Boxing Mocap Tool.bat`.

### Manual mode

1. Double-click `index.html`. Chrome opens it from `file://`.
2. Click "Choose File" under Model, pick a `.glb`.
3. Grant webcam permission when prompted.
4. (Optional) For best results, open via `chrome.exe --allow-file-access-from-files index.html`
   if you hit CORS issues with the CDN scripts in some Chrome builds.

No build step. No local server. No npm install. Internet required for the
CDN libs (three.js 0.140, MediaPipe Holistic, KalidoKit 1.1.5, DRACOLoader,
Google's hosted Draco decoders for the compressed UK1 GLB).

## Converting UK1Outboxer FBX -> GLB (Blender)

**Easy path:** just double-click `_convert_uk1.bat` in this folder. It
runs Blender 5.1 headless against `_convert_uk1.py`, which strips
textures, drops non-essential meshes (hair, lashes, stubble, glove
attachments), decimates body/eyes/teeth/shorts, Draco-compresses the
result, and writes `uk1_outboxer.glb` here (~67 MB). Takes 30-60 s.
Check `_convert_uk1.log` if it fails.

Reference character path (hardcoded in `_convert_uk1.py`):
`D:\Boxing game\Assets\BoxingGame\Characters\UK1Outboxer\uk1_outboxer.fbx`

### Manual path (if you need full materials/no decimation)

In Blender 3.6+:

1. File -> New -> General. Delete the default cube/light/camera.
2. File -> Import -> FBX (.fbx).
   - Point at `uk1_outboxer.fbx`.
   - Under Armature: enable Automatic Bone Orientation = OFF
     (preserve CC bone roll).
   - Under Armature: Ignore Leaf Bones = OFF.
   - Scale = 1.0.
3. With the armature selected, verify in the Outliner that bones are
   named `CC_Base_Hip`, `CC_Base_L_Upperarm`, `CC_Base_R_Forearm`, etc.
   If Blender renamed anything, undo and re-import.
4. (Optional) Apply Transforms (Object -> Apply -> Rotation & Scale) so
   the character is upright Z-up before export, or trust the FBX axes.
5. File -> Export -> glTF 2.0 (.glb/.gltf).
   - Format: glTF Binary (.glb)
   - Include: Selected Objects = ON (after selecting both armature and mesh)
   - Transform: +Y Up = ON
   - Geometry: Apply Modifiers = ON, UVs ON, Normals ON
   - Animation: Animation = OFF (we record our own), Skinning = ON,
     Bone Influences = 4
   - Save as `uk1_outboxer.glb` somewhere convenient.

In the tool, click "Choose File" under Model and pick that GLB. The
status bar shows total bones and how many of the 17 driven CC5 bones
were matched (substring match — Reallusion sometimes capitalises
"Upperarm" vs "UpperArm", we handle both).

## Modes: Live Webcam vs Pre-recorded Video

The top-left "Mode" panel toggles between two input sources. Both feed
the *same* MediaPipe Holistic + KalidoKit + CC5-retarget pipeline, so
calibration, bone corrections, recording, trimming, and export are
identical across modes — only the source of the pixels changes.

- **Live Webcam** (default) - real-time tracking off your webcam, same
  behaviour as the original tool. T-pose calibration uses a 3-second
  hold.
- **Pre-recorded Video** - feeds a `.mov/.mp4/.webm/.avi/.mkv` file
  through MediaPipe one frame at a time. Useful for batch-processing
  saved footage (e.g. boxing takes shot on an iPhone). T-pose
  calibration captures from whatever frame the scrubber is parked on.

Switching modes cleanly tears down the active source (releases the
webcam, pauses the video) and frees the MediaPipe instance, then sets
up the new source. The smoothing (one-euro) filters are reset so noise
characteristics from the previous source don't bleed in.

## Workflow A — Live Webcam (the calibration loop)

1. Load `uk1_outboxer.glb`.
2. Click "Start Webcam". Wait for "Tracking: OK" in the status bar.
3. Stand in T-pose (arms out, palms forward, feet shoulder width) and
   click "Capture T-Pose (3s)". Hold still until you see the green check.
4. Move. The character should mimic. Most likely the arms will be
   rotated wrong — that is the CC5 roll problem this tool exists to fix.
5. Open the "Per-Bone Correction (CC5)" panel on the right. Sliders go
   from -180 to +180 degrees per axis. Edit `LeftUpperArm.z`,
   `RightUpperArm.z`, etc. until arms behave on screen.
   You can also live-tune from the DevTools console:
   ```js
   window.boneCorrections.LeftUpperArm.z = 85;
   ```
6. When you like the rig, click "Save Preset" -> stored in localStorage.
   Click "Export JSON" to save a portable copy.
7. Click "Start Recording", do a punch, click "Stop".
8. Use the timeline scrubber at the bottom of the viewport. `I` marks IN
   at the playhead, `O` marks OUT. Toggle "Loop trim" to verify the take
   reads cleanly. The exported clip uses only the IN..OUT region.
9. Set category (Jab/Cross/Hook/etc.) and grade (A/B/C/Skip) per take.
10. "Export Selected" downloads one GLB per non-Skip take. Click
    "Verify Re-load" to round-trip-check the most recent export.

## Workflow B — Pre-recorded Video import

For hours of saved footage (e.g. iPhone IMG_*.MOV takes from the
`Desktop\markerless mocap\Rep1`, `Rep2`, `Rep3` folders).

1. Load `uk1_outboxer.glb` (same as live mode).
2. Click the "Pre-recorded Video" tab in the Mode panel at the top of
   the left column. The Webcam panel hides; a Video File panel appears.
3. Click "Choose File" under Video File and pick a `.MOV` / `.mp4` /
   `.webm` / `.avi` / `.mkv`. Browser streams the file (don't worry
   about size — Sammy's ~1.5 GB iPhone clips work fine). Filename,
   resolution, and duration appear in the panel and on the status bar
   ("Mode: Video — IMG_0054.MOV").
4. Use the **scrub bar** (or Step button, ~1/30s per click) to find a
   frame where the subject is in T-pose (or whatever rest pose the take
   started with — arms out at sides is fine; KalidoKit just needs a
   stable reference frame for the bone-delta math).
5. Click **"Capture T-Pose (current frame)"** in the Video panel. Status
   bar reads "Calibrated: Yes". (Under the hood: MediaPipe re-runs on
   the current paused frame for 3 seconds to gather stable samples,
   then averages — same code path as live calibration.)
6. (Optional) Switch the **Speed** dropdown to `0.5x` or `0.25x`.
   MediaPipe Holistic takes 50-100 ms per frame on a typical laptop;
   playing the video slower means every frame gets processed instead of
   dropped. The exported clip will still play back at the original
   real-world speed (timestamps are sampled from `video.currentTime`,
   not wall-clock, so 0.25x playback for 40s of wall-clock produces a
   10s animation clip).
7. Scrub to a few seconds before the punch starts. Click **"Start
   Recording"**, then click **"Play"** on the video. The character
   mimics the footage; QuaternionKeyframeTracks accumulate.
8. Click **"Stop"** (or let the video reach the end — recording
   auto-stops on the `ended` event). The take appears in the Takes list
   exactly like a webcam recording.
9. Scrub, trim with `I` / `O`, grade, and "Export Selected" — same as
   live workflow.
10. To process another take from the same shoot: pick a new file (the
    previous object URL is auto-revoked to free memory), scrub, and
    record again. Calibration carries over if the subject and camera
    setup didn't change between takes.

### Caveats / tips for video mode

- **Pick the cleanest T-pose frame you can find** in each session. If
  the subject never holds T-pose on camera, scrub to where they're
  closest to a neutral stand-square pose; the bone-delta math doesn't
  need a perfect T, just a *consistent* reference.
- **Slower playback = better tracking** but more wall-clock time. For a
  60-second take at 0.25x, plan on 4 minutes of wall-clock processing.
- **Video element reuse**: picking a new file revokes the previous blob
  URL and reloads, so loading another 1.5 GB clip after the first one
  doesn't double memory usage.
- **Drop frames, not queue**: if MediaPipe is mid-inference when the
  next rAF fires, the new frame is skipped (the `videoIsProcessing`
  flag). This is the right call — queueing would cause processing to
  lag the video and eventually run out of memory on long clips.
- **Pause + scrub does live tracking**: even paused, scrubbing fires a
  `seeked` event that triggers a fresh MediaPipe run on the current
  frame. So you can scrub through a take frame-by-frame and watch the
  character pose update in real time.

## Split-panel layout

Both `index.html` (desktop) and `ipad.html` use a split layout:

- **Left panel** (~30% width on landscape, top ~30% height on portrait
  phones) — the **real-life camera** or pre-recorded video, with the
  MediaPipe landmark dots drawn directly on top. This is the QC view for
  "is MediaPipe actually finding my joints?"
- **Right panel** (~70%) — the **clean 3D scene**: the UK1 character
  mimicking the motion, plus the cyan stick figure showing what
  MediaPipe thinks the skeleton looks like. This is the QC view for "is
  retargeting working?"

The two panels are intentionally separate so neither crowds the other.
The stick-figure overlay still has three modes (`1` / `2` / `3` keys on
desktop, on-screen seg control on iPad).

### Big 3D mode

Press `B` (desktop) or tap the "Big 3D" button (top-right of the 3D
scene panel on iPad) to shrink the camera feed to a small corner
thumbnail and let the 3D scene fill the stage. Press again to return to
split view.

### Popout 3D (desktop only)

Press `P` (desktop) or click the "Popout 3D" button to open the 3D scene
in a separate browser window. Drag it to a second monitor so the 3D
character has its own dedicated screen, while the main window keeps the
left/right control panels and the camera feed. The popout window shares
the original window's three.js scene by reference and renders it from
its own free camera (independent OrbitControls), so bone state stays
synced with zero broadcast overhead. The popout is hidden on iPad
because iOS Safari doesn't support multi-window.

## Hotkeys

- `1` - stick-figure side-by-side (raw MediaPipe pose, 1.5m to character's left)
- `2` - stick-figure overlapped on character + per-bone direction arrows
        (cyan = MediaPipe-says, magenta = bone-actual). When they disagree,
        that bone's correction quaternion is wrong.
- `3` - stick-figure hidden
- `S` - toggle skeleton overlay
- `B` - toggle Big 3D mode (camera shrinks to corner thumbnail)
- `P` - open the 3D scene in a popout window for a second monitor
- `I` - set trim IN at playhead
- `O` - set trim OUT at playhead
- `Space` - play/pause the take timeline (NOT the source video; the
            video file has its own Play/Pause/Step buttons)

## Diagnostic stick-figure overlay

The cyan stick-figure is the raw MediaPipe Holistic pose landmarks
rendered as joint spheres and bone segments — the *source* signal feeding
KalidoKit. The CC5 character is the *target* — what your retargeting
math produces. They should agree. When they don't, you have your bug
exactly localized.

Press `2` for the overlay mode: the stick figure is anchored at the
character's hip (semi-transparent so you can see through it). Per-driven-
bone arrows appear: cyan = the direction MediaPipe says the bone should
point (from landmark head to landmark tail), magenta = the direction the
CC5 bone is *actually* pointing in world space. A clean retarget = both
arrows superimposed. A wrong correction quaternion = the magenta arrow
pointing somewhere else entirely. Adjust `window.boneCorrections` until
they match.

## Live tuning surfaces

Everything below is hot-reloadable from DevTools without restarting:

- `window.APP` - full app state (scene, bones, takes, recording flags)
- `window.charBones` - logical-name -> THREE.Bone map (17 bones)
- `window._allBones` - every bone in the GLB by exact name
- `window.boneCorrections` - per-bone Euler-degree corrections object
- `APP.oneEuroParams` - filter parameters; sliders in the right panel
  edit these and updates propagate per-frame

## Verification (pre-export gate)

Before exporting, the tool verifies the trimmed clip:

- `clip.duration > 0`
- At least one KeyframeTrack with `>= 2` keyframes
- First keyframe at `t == 0`
- Last keyframe at `clip.duration`

If any check fails, the export aborts and a red toast appears. The
"Verify Re-load" button parses the exported GLB back through GLTFLoader
to confirm the animation survived serialisation.

## QC features

- Foot contact HUD: live foot Y in world space, flashes red over 0.05 m
- Bone rotation HUD: live Euler degrees on the major joints; flashes red
  if any axis exceeds 180 degrees (likely gimbal flip or sign error)
- Despike: detects single-frame quaternion jumps > 60 deg and slerps
  between neighbours
- Auto-trim: removes leading and trailing static frames (below motion
  threshold) so takes start at the wind-up and end at retraction
- Compare panel (collapsed by default): load a second `.glb` or `.bvh`
  side-by-side on a duplicate character

## Known limitations

- KalidoKit was authored for VRM (Z+ forward) rigs. CC5 uses different
  bone roll conventions. The correction quaternions handle this but you
  must dial them in once per character body type — that is what `Save
  Preset` is for. See `PRESET_CC5_DEFAULTS.json` for starting values.
- MediaPipe Holistic body solver is good for upper-body boxing motion
  but legs/footwork are noisier. Auto-trim and the bone HUD help catch
  the worst frames.
- No finger tracking is applied to the character (CC5 fingers ignored).
- Hip vertical (Y) is intentionally NOT driven from the webcam — it is
  noisy and tends to teleport the character. Hip XZ is driven gently
  (0.3 multiplier).
- Webcam must be a single user, full body in frame, well lit.
- BVH compare uses three.js BVHLoader; it loads the skeleton + clip but
  does not retarget — it just plays the BVH on its own bone hierarchy
  for visual comparison.

## File layout

- `index.html` - the entire app (HTML + CSS + ~1900 lines of vanilla JS)
- `README.md` - this file
- `BROWSER_MOCAP_TEST_CHECKLIST.md` - 15-step manual verification list
- `PRESET_CC5_DEFAULTS.json` - starting bone correction values for CC5
- `uk1_outboxer.glb` - pre-converted UK1 character (~67 MB, Draco-
  compressed, textures stripped, hair/eyelashes/stubble removed,
  body/eyes/teeth/shorts decimated for browser speed). Committed to
  the repo so GitHub Pages serves it same-origin. On `file://` the
  tool hands the local path directly to `GLTFLoader`; on Pages it's
  streamed via `fetch()` with progress UI and cached in IndexedDB
  after the first load.
- `LAUNCH_MOCAP.bat` - source for the Desktop one-click launcher.
- `_convert_uk1.bat` + `_convert_uk1.py` - the Blender headless
  conversion (FBX -> compact GLB). Rerun if the source FBX changes.
- `_convert_uk1.log` - last conversion log, useful when debugging.
- `one_click_test.png` - verification screenshot of the tool launched
  from the Desktop shortcut.

## Debugging

Open DevTools (F12) on load. The console logs:

- Every bone name discovered in the GLB
- Which logical bones were mapped to which CC5 bone
- Any bone that could NOT be mapped (warnings)
- KalidoKit solve failures
- Export verification details

If arms look mirrored, flip `RightUpperArm.z` from `-90` to `+90`.
If forearms hyperextend backwards, try `LeftLowerArm.x = 180`.
If the whole character tilts, check `Hips` corrections last.
