# Presentations

## Linux Zero Trust — Compliance-First Briefing

**Edit content, not the generator.**

| File | Role |
|------|------|
| **`briefing.yaml`** | Preferred human-editable slide copy (YAML) |
| **`briefing.json`** | Same content as JSON (used if `js-yaml` is not installed) |
| **`ltz-deck.js`** | Layout / theme engine only — no slide prose |
| `Linux-Zero-Trust-Briefing.pptx` | Build output |

### Build

```bash
cd docs/presentations
npm install pptxgenjs          # required
npm install js-yaml            # optional — enables reading briefing.yaml
node ltz-deck.js
# or: OUT=./out.pptx node ltz-deck.js
```

Load order: `briefing.yaml` (if present and `js-yaml` available) → else `briefing.json`.

### After editing copy

1. Change titles/bodies in `briefing.yaml` (or `.json`).
2. Keep YAML and JSON in sync if you use both (or only maintain one).
3. Run `node ltz-deck.js`.

### Style

- Body text: black on white  
- Accent: navy `#11134A`, blue `#1C83C9` (EMSL public brand guide, Oct 2025 — PNNL user facility)  
- Font: Arial  
- IAM asks: plain English (no internal ticket codes)

### Slide types in content file

`title` · `cards` · `recommendation` · `planes` · `steps` · `reject_list` · `phases` · `numbered_asks` · `success`

Architecture: [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md)
