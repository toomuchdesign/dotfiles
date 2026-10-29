---
name: too-pr-image-diff
description: Use when asked to review, inspect, compare, or visualize the image changes in a GitHub pull request, such as VRT baseline or snapshot PNG updates. Triggers on "show the visual diffs of this PR", "what changed in these screenshots", "image diff for PR <url>", or a PR URL whose changed files are mostly images. Starts a local browser viewer that lists every changed image with split, slider, and pixel-diff views, and each changed region numbered with before/after crops.
---

# pr-image-diff

A local viewer for the images a PR changes. `serve.mjs` uses `gh` to download each changed image at the PR's merge base and head, then serves `viewer.html` on `127.0.0.1` and opens the browser. The browser does the pixel diff. Nothing to install. The diff library loads from a CDN.

## Run

Start it in the background (Bash `run_in_background: true`). It keeps serving until the user clicks **Close** in the page or the process is stopped:

```bash
node ~/.claude/skills/too-pr-image-diff/serve.mjs <pr-url> [--no-open]
```

- Works with github.com and GitHub Enterprise hosts. `gh` must be logged in to the PR's host (`gh auth status --hostname <host>`).
- `PORT=4321` pins the port. The default is a random free port.
- Once it prints `Viewer: http://127.0.0.1:…`, give the user that URL. Use `--no-open` if they don't want a browser tab opened.

## What the user sees

- **Sidebar**: every changed image, with its change count (`new` / `deleted` for added or removed files).
- **Views**: Split (before | after), Slider (drag to wipe), Diff (changed pixels in magenta over a faded "after" image). Zoom: fit to 800%.
- **Change list**: each region numbered `1, 2, …` with its size and before/after crops. The same numbers mark boxes on the image. **Focus** zooms and scrolls to the region.
- **Threshold** and **Anti-aliasing**: the diff runs [pixelmatch](https://github.com/mapbox/pixelmatch) 8.0.0, loaded from jsDelivr, so the page needs network. The defaults (threshold 0.1, anti-aliasing ignored) are the ones Playwright's `toHaveScreenshot` uses. Tick **Anti-aliasing** to also count pixels pixelmatch treats as anti-aliasing.
- Keys: `j`/`k` file, `n`/`p` change, `1`/`2`/`3` view.

A changed file with "No pixel differences" means the PNG bytes changed and the pixels didn't (re-encoded or metadata only).
