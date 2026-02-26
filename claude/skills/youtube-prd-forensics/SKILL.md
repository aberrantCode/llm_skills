---
name: youtube-prd-forensics
description: Create or update a detailed Product Requirements Document from a YouTube demo video using evidence-first analysis. Use when the user wants reproducible requirements tied to timestamps, transcript/description/comments, keyframe evidence, and embedded screenshots persisted in the project.
---

# YouTube PRD Forensics

## Workflow

Execute this workflow in order using Claude's available tools (Bash, Read, Write).

1. Prepare output locations under `docs/`.
2. Download and persist the source video locally.
3. Extract YouTube page artifacts (description, metadata, comments, transcript/subtitles).
4. Generate transcript from local video if YouTube transcript is missing.
5. Extract keyframes at 5-second intervals and build an index.
6. Analyze keyframes and transcript together to derive requirements.
7. Persist high-resolution screenshots for specific requirements.
8. Update or write `docs/PRD.md` with timestamped requirements and embedded images.
9. Delete keyframes and retain only final artifacts.

Use `references/prd-evidence-checklist.md` as the completion gate.

## Required Persisted Artifacts

Keep these files:

- `docs/<project>_reference_1080p.<ext>` (downloaded video)
- `docs/transcript_notes.md` (curated transcript with timestamps)
- `docs/PRD.md` (final requirements document)
- `docs/images/screenshots/*` (selected full-frame or cropped screenshots used by PRD)
- `docs/youtube_metadata.json`
- `docs/youtube_description.txt`
- `docs/youtube_comments.json`

Delete temporary keyframes at the end (e.g. `docs/images/video_frames_5s/`).

## Commands

Run via the Bash tool from the repo root. Replace `<YOUTUBE_URL>` and `<BASENAME>`.

### 1. Prepare directories

```bash
mkdir -p docs/images/screenshots docs/images/video_frames_5s
```

### 2. Download video

```bash
yt-dlp -f "bv*[height<=1080]+ba/b[height<=1080]" \
  -o "docs/<BASENAME>_reference_1080p.%(ext)s" "<YOUTUBE_URL>"
```

### 3. Extract page metadata, description, and comments

```bash
yt-dlp --skip-download --write-info-json --write-description --write-comments \
  -o "docs/youtube.%(ext)s" "<YOUTUBE_URL>"
mv -f docs/youtube.info.json docs/youtube_metadata.json
mv -f docs/youtube.description docs/youtube_description.txt
mv -f docs/youtube.comments.json docs/youtube_comments.json
```

### 4. Extract transcript/subtitles from YouTube when available

```bash
yt-dlp --skip-download --write-auto-subs --write-subs --sub-langs "en.*" \
  --sub-format "vtt" -o "docs/youtube.%(ext)s" "<YOUTUBE_URL>"
```

### 5. Generate transcript from local video (when YouTube transcript is unavailable)

Use whisper via the Bash tool. Always write output to `docs/transcript_notes.md`.

```bash
whisper "docs/<BASENAME>_reference_1080p.mp4" \
  --model base --language en --output_format vtt \
  --output_dir docs/
```

Then read the `.vtt` output and write a curated `docs/transcript_notes.md` with timestamps and speaker cues using the Write tool.

### 6. Extract keyframes at 5-second intervals

```bash
ffmpeg -i "docs/<BASENAME>_reference_1080p.mp4" \
  -vf "fps=1/5" \
  -frame_pts 1 \
  "docs/images/video_frames_5s/frame_%05d.jpg"
```

Build a frame index by listing the output directory and mapping each filename to its timestamp (`frame number × 5 seconds`).

### 7. Capture requirement screenshots

For each requirement identified during analysis, extract the exact frame using ffmpeg:

```bash
ffmpeg -ss <TIMESTAMP> -i "docs/<BASENAME>_reference_1080p.mp4" \
  -frames:v 1 -q:v 2 \
  "docs/images/screenshots/<NN>_<descriptive_name>.jpg"
```

### 8. Cleanup keyframes after PRD completion

```bash
rm -rf docs/images/video_frames_5s
```

## PRD Content Requirements

Enforce all of the following in `docs/PRD.md`:

- Include source metadata: video URL, title, creator, publish date, duration, description summary, notable comments.
- Include requirement sections that map features/behaviors to explicit timestamps.
- Embed screenshots under each major requirement section using relative paths (`images/screenshots/<file>`).
- Distinguish observed facts from inferred requirements.
- Capture UI controls, data sources, layer toggles, failure states, and workflow behavior shown in the video.
- End with a modification/change-summary table whenever editing an existing PRD.

## Screenshot Guidance

- Save screenshots into `docs/images/screenshots/`.
- Use full keyframes when context matters.
- Use cropped images when isolating a control/feature is clearer.
- Name files descriptively with numeric prefixes for stable PRD references, e.g. `01_hud_overview.jpg`.
