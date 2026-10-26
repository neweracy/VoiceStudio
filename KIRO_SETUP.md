# Kiro Setup (neweracy fork)

Personal fork setup for `neweracy/VoiceStudio`. Not upstream documentation — kept
separate from `README.md` on purpose.

## Remotes

| Remote     | URL                                          | Use                        |
|------------|----------------------------------------------|----------------------------|
| `origin`   | https://github.com/neweracy/VoiceStudio.git  | My fork (push here)        |
| `upstream` | https://github.com/debpalash/VoiceStudio.git | Source repo (pull updates) |

Recreate if needed:

```bash
git remote add origin   https://github.com/neweracy/VoiceStudio.git
git remote add upstream https://github.com/debpalash/VoiceStudio.git
```

## Staying up to date

`scripts/kiro-update.sh` is **read-only by default** — it fetches `upstream/main`
and tells you how far behind you are. It never merges or builds unless asked.

```bash
./scripts/kiro-update.sh            # fetch + report only (safe)
./scripts/kiro-update.sh --merge    # merge upstream/main into current branch
./scripts/kiro-update.sh --build    # bun install + electron typecheck
./scripts/kiro-update.sh --merge --build
```

`--merge` refuses to run if the working tree is dirty (commit or stash first), so
it never discards local work.

## SessionStart hook

`.kiro/hooks/kiro-upstream-notify.json` runs on every session start **in this
workspace only**. It calls the update script in read-only mode and prints the
"behind/ahead" line. It does **not** merge, pull, or build — deliberately, so no
unreviewed upstream code ever lands or runs automatically. Run the merge/build
yourself when you choose.

## Local environment notes

- Model/download caches are pinned to the D: drive via `HF_HOME`,
  `HF_HUB_CACHE`, `TORCH_HOME`, `UV_CACHE_DIR` (set at the user level).
- `AWS_REGION` / `AWS_DEFAULT_REGION` = `us-east-1` (set at the user level).
  AWS credentials are read from `~/.aws/credentials` by boto3 — never copied
  into the repo.
- Dev ports: backend `3900`, web UI `3901`, Electron dev `3902`
  (`config/app.json`). Note `8080` on this machine is an unrelated EDB Apache
  service, not VoiceStudio.

## Added Twi/Akan ASR models

Two Ghanaian-language Whisper fine-tunes added to `backend/config/models.yaml`
(with licence records in `backend/config/model_licenses.json`):

| Repo                                   | Base          | Engine           | Notes                    |
|----------------------------------------|---------------|------------------|--------------------------|
| `tiffany101/whisper-small`             | whisper-small | `pytorch-whisper`| Accurate; fits 4 GB GPU  |
| `dkt-py-bot/Whisper-FineTuned-DL-Twi`  | whisper-tiny  | `pytorch-whisper`| Fast, lower accuracy     |

Both run on the `pytorch-whisper` engine (CUDA/ROCm) — raw PyTorch weights, not
CTranslate2, so faster-whisper cannot load them.
