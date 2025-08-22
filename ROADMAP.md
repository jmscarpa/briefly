# Roadmap — v0.2.0

This document captures the scoped features and implementation details targeted for **v0.2.0** of **briefly**.

## Goals

* Improve ergonomics (command aliases, date shortcuts, dry-run).
* Add multilingual output support.
* Support customizable prompting for more control over style and structure.

---

## 1) Command aliases / shortcuts

### Design

* Add a lightweight alias layer in `cli.sh` before dispatch.
* Aliases should be **discoverable** via `briefly help` and `briefly <alias> --help`.

### Aliases

* `briefly g` → `briefly generate`
* `briefly .` → `briefly setup` (mnemonic: “dot initializes here”)
* (Optional) `briefly p` → `briefly publish`

### Acceptance Criteria

* `briefly g --date 2025-08-18` behaves exactly like `briefly generate --date 2025-08-18`.
* `briefly .` opens the same interactive setup as `briefly setup`.
* `briefly help` lists aliases under an **Aliases** section.

---

## 2) Multilingual output

### Design

* Introduce `--lang <code>` flag for `briefly generate` to set output language.
* Supported: ISO language codes (e.g., `en`, `pt`, `es`, `fr`, `de`). Default: `en`.
* Add `DEFAULT_LANG` to project `.briefly` (optional). CLI flag overrides config.
* Prompt will include an explicit instruction to respond in the selected language.

### Config

```ini
# .briefly
DEFAULT_LANG=en
```

### CLI

```bash
briefly generate --lang pt
briefly generate --lang es --date 2025-08-18
```

### Prompt Change (example)

> "Summarize the commits below into a weekly product changelog in **{{LANG}}**, formatted as Markdown."

### Acceptance Criteria

* Output language matches `--lang` if provided; otherwise `DEFAULT_LANG` or fallback to `en`.
* No change to existing behavior when flag/config absent.

---

## 3) Date shorthand: `7d`, `1w`, `20d`

### Design

* Add `--since` flag to `generate` that accepts shorthand:

  * `Nd` (days), `Nw` (weeks), `Nm` (months \~ 30d), `Ny` (years \~ 365d)
* Convert to an absolute date (YYYY-MM-DD) before passing to `git log --since`.
* If `--date` and `--since` are both provided, **`--date` wins** (explicit beats relative).

### Examples

```bash
briefly generate --since 7d
briefly generate --since 1w
briefly generate --since 2m
```

### Acceptance Criteria

* `--since 7d` is equivalent to `--date $(date -v-7d +%F)` on macOS or GNU date equivalent.
* Works cross-plat (macOS/Linux). Document Windows/WSL note.

---

## 4) Dry-run

### Design

* `generate`: `--dry-run` prints the **OpenAI request payload** (redacted key) and the first 600 chars of commits; **does not call** the API.
* `publish`: `--dry-run` prints the **Discord payload JSON** and the resolved webhook URL (redacted); **does not POST**.

### CLI

```bash
briefly generate --since 1w --lang pt --dry-run
briefly publish --dry-run
```

### Acceptance Criteria

* No network calls performed in dry-run mode.
* Exit code 0; clear message that it was a dry run.

---

## 5) Customizable prompt

### Design

* Support both **file-based** and **inline** prompt customization.
* Precedence: `--prompt-file` > `PROMPT_FILE` in `.briefly` > built-in default.
* Template variables available:

  * `{{REPO}}`, `{{PERIOD}}`, `{{LANG}}`, `{{DATE}}` (today), `{{KIND}}` (project kind)
* If the custom prompt omits language instructions, CLI will append a line enforcing `{{LANG}}`.

### Config

```ini
# .briefly
PROMPT_FILE=.briefly.prompt.md
```

### Files

* `.briefly.prompt.md` lives at repo root by default (path configurable).

### CLI

```bash
briefly generate --prompt-file custom-prompt.md
```

### Acceptance Criteria

* When a prompt file is provided, it’s read, templated, and used as the final user/system message(s).
* Fallback to built-in prompt when no custom prompt configured.

---

## Backward Compatibility

* Existing commands continue to work without new flags.
* Default behavior remains English output, no aliases required, and no prompt file needed.

---

## Implementation Plan

* [ ] **CLI**: Add alias routing in `cli.sh` (map `g`→`generate`, `.`→`setup`, `p`→`publish`).
* [ ] **Config**: Add `DEFAULT_LANG` and `PROMPT_FILE` support in `lib/common.sh`.
* [ ] **Generate**:

  * [ ] Add `--lang <code>` flag and wire to prompt.
  * [ ] Add `--since <expr>` parser (`Nd|Nw|Nm|Ny`) → absolute date.
  * [ ] Add `--dry-run` behavior.
  * [ ] Prompt templating and `--prompt-file`.
* [ ] **Publish**:

  * [ ] Add `--dry-run` behavior (print payload + URL).
* [ ] **Docs**:

  * [ ] README: installation (scoped or renamed pkg), examples with `--since`, `--lang`, `--prompt-file`.
  * [ ] Add `.briefly.prompt.md` example file.
  * [ ] Update CONTRIBUTING with dry-run/testing notes.
* [ ] **QA**:

  * [ ] Manual tests on macOS + Linux.
  * [ ] Validate truncation and Discord limits unchanged.

---

## Notes / Open Questions

* Do we want a `LANG` inference based on system locale if nothing is set? (default remains `en` for now)
* Should we offer a built-in `--format html` (future 0.3.x)?
* Consider `--since last-tag` helper (resolve last annotated tag) as a follow-up.
