---
name: youtube-extraction
description: >
  Reconstruct locally the solution depicted in a YouTube video — files, configurations,
  commands, transcripts, and supporting artifacts. Use whenever the user wants to extract,
  recreate, mirror, scrape, harvest, or rebuild content from a YouTube video, even if they
  don't say "extract" — phrases like "recreate the project from this video", "pull the
  files out of this tutorial", "rebuild what they showed", or "scrape this YouTube
  walkthrough" all qualify. Each thin command in this bundle requires a YouTube URL and a
  free-text request describing what to extract; if either is missing, this skill MUST use
  the AskUserQuestion tool to elicit the missing parameters before proceeding.
---

# YouTube Extraction

You are the domain expert for reconstructing locally the solution depicted in a YouTube
video. Your job is to turn a video into real artifacts on disk: source files, transcripts,
comments, screenshots, and a markdown report describing what was extracted and how it maps
back to the video.

This skill is a thin orchestrator. The deep domain knowledge lives in sub-skills under
`sub-skills/`. Each thin command in `commands/` invokes this skill and names a single
operation; this skill chains the right sub-skills to fulfil that operation.

---

## Parameter Contract

Every operation in this skill requires two inputs:

| Parameter | Description |
|-----------|-------------|
| `url`     | A YouTube video URL (`https://www.youtube.com/watch?v=…` or short form). |
| `request` | Free-text description of what within the video should be extracted (e.g. "all source files shown in the IDE", "the docker-compose stanza around 4:20", "the slash-command files the speaker pastes"). |

### Eliciting missing parameters

If the invocation does not provide both `url` and `request`, you MUST use the
`AskUserQuestion` tool to prompt for whatever is missing — never inline-print a
free-text question.

- **URL missing:** ask one question with header `YouTube URL` whose options are
  "Paste the URL" (Other) and "Cancel". Treat the user's free-text answer as the
  URL and validate it matches a YouTube host before proceeding.
- **Request missing:** ask one question with header `What to extract` whose options
  reflect the calling thin command's defaults (for `/recreate-files` the recommended
  default is "All files shown or discussed in the video"). Provide a "Custom focus"
  Other slot. The user's selection is the `request`.
- **Both missing:** ask both in a single `AskUserQuestion` call (one question for
  URL, one for the extraction request).

If a thin command has a sensible default for `request` (e.g. `/recreate-files`
defaults to "all files"), state the default in your prompt rather than blocking on
an answer the user can shrug at. Always block on a missing `url`.

---

## Workspace Layout

All extracted artifacts live under a single directory derived from the video's
basename. Use `<basename>` = sanitised slug of the video title or video id.

```
docs/youtube-extraction/<basename>/
├── video.<ext>                # downloaded video (highest practical resolution)
├── metadata.json              # yt-dlp info-json
├── description.txt            # video description
├── transcript.md              # timestamped transcript
├── comments.json              # comments + threads
├── frames/                    # extracted frames (deleted after extraction unless retained)
├── files/                     # reconstructed source files (mirrors repo structure)
├── screenshots/               # full-frame or cropped images referenced from EXTRACTION.md
└── EXTRACTION.md              # final report
```

Only the temporary `frames/` directory is allowed to be deleted at the end.
Everything else is a persisted artifact and should remain on disk.

---

## Thin Commands and the Sub-Skills They Drive

Each thin command in `commands/` invokes this skill with a named operation. The
operation is implemented by chaining sub-skills.

| Command          | Operation         | Sub-skills invoked, in order |
|------------------|------------------|------------------------------|
| `/recreate-files`| `recreate-files` | video-acquisition → transcript-acquisition → comment-harvesting → frame-extraction → frame-content-recognition → file-reconstruction → extraction-reporting |

When new thin commands are added, append them to this table and document the
operation below.

---

## Operation: recreate-files

**Goal.** Inspect every relevant signal in the video — frames, transcript, comments,
description — to identify files the creator discusses or shows. Recreate each one on
disk inside the current repo at a path inferred from the video context, deduplicating
lines that appear across multiple frames. End with a markdown report.

**Steps.**

1. **Validate parameters.** Apply the parameter contract above. Block on missing
   `url`; default `request` to "All files shown or discussed in the video" if the
   user gives no narrowing focus.

2. **Acquire the video.** Apply the `video-acquisition` sub-skill. Resolution
   matters here because OCR depth scales with pixel density — prefer 1080p or
   higher when the video offers it.

3. **Acquire the transcript.** Apply the `transcript-acquisition` sub-skill. If
   YouTube has auto-subs, use them; otherwise transcribe the local file.

4. **Harvest comments and metadata.** Apply the `comment-harvesting` sub-skill.
   Comments and the description often contain the canonical filenames or repo URLs
   that the speaker reads aloud — treat them as a primary source.

5. **Extract frames.** Apply the `frame-extraction` sub-skill in *file-reconstruction*
   mode (denser sampling, scene-aware) so consecutive frames overlap enough to
   stitch multi-page file content.

6. **Identify file content in frames.** Apply the `frame-content-recognition`
   sub-skill. For each frame, decide whether it shows file content (IDE, terminal
   `cat`, slide, README pane, etc.) and capture (path, language, visible lines).

7. **Reconstruct files on disk.** Apply the `file-reconstruction` sub-skill. For
   each unique file path detected:
   - Stitch its visible-line ranges across frames into a single canonical buffer
     without duplicating overlapping lines.
   - Cross-check the result against any verbatim quotes in the transcript or
     comments — these often supply lines that scrolled past too fast for OCR.
   - Place the file at a path appropriate to the calling repo's conventions
     (defer to existing folder structure if the repo already has one;
     otherwise honour the path shown in the video relative to the repo root).

8. **Generate the report.** Apply the `extraction-reporting` sub-skill to produce
   `docs/youtube-extraction/<basename>/EXTRACTION.md`.

9. **Clean up.** Delete the `frames/` working directory after successful
   reconstruction. Never delete `video.*`, transcripts, comments, screenshots, or
   the report.

---

## Cross-Operation Principles

These apply to every operation, present or future:

- **Evidence first, inference second.** When the transcript and a frame disagree,
  prefer the transcript for words and the frame for code. Note the disagreement
  in `EXTRACTION.md`.
- **Never duplicate lines.** Scrolling content produces overlapping frames;
  stitch by longest common subsequence, not by concatenation.
- **Respect the repo.** If the calling repository already has `src/`, `scripts/`,
  `docs/`, etc., place reconstructed files inside the matching folders. Only
  invent a new top-level folder when no contextual match exists.
- **All user prompts go through `AskUserQuestion`.** Never write "type yes/no"
  or otherwise inline-print a question.
- **Idempotence.** Re-running a command on the same URL must not corrupt
  prior artifacts. If a target file already exists with content from a prior
  extraction, diff before overwriting and surface the conflict via
  `AskUserQuestion`.

---

## Tooling Prerequisites

The sub-skills assume these tools are available on PATH. If any is missing, fall
back to the documented alternatives in the relevant sub-skill.

- `yt-dlp` — video, metadata, comments, subtitles
- `ffmpeg` / `ffprobe` — frame extraction, scene detection
- `whisper` or `whisper.cpp` — transcript fallback when YouTube auto-subs are
  absent
- A multimodal vision model (this assistant's own image-reading capability via
  the `Read` tool on PNG frames) — frame content recognition

---

## Diagram

[View diagram](diagram.html)
