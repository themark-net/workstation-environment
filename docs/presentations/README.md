# Presentations

## Linux Zero Trust — Compliance-First Briefing

High-level deck for security architecture, identity, and platform leadership.

| File | Role |
|------|------|
| `ltz-deck.js` | PptxGenJS source of truth |
| `Linux-Zero-Trust-Briefing.pptx` | Built locally via `node ltz-deck.js` |

### Regenerate

```bash
npm install pptxgenjs
node docs/presentations/ltz-deck.js
# or: OUT=./Linux-Zero-Trust-Briefing.pptx node docs/presentations/ltz-deck.js
```

### Visual style

- **Body text:** black on white content slides  
- **Accent:** deep navy `#11134A` and science blue `#1C83C9` (aligned with public **EMSL Brand & Style Guide, Oct 2025** — EMSL is a PNNL user facility). Full official PNNL `.pptx` templates are not published for external download; use lab Organizational Asset Library / brand kits when presenting officially.  
- **Fonts:** Arial (widely available; EMSL lists Arial Nova on Microsoft products)

### Language

IAM asks are written in plain English (enroll Linux in Intune, accept compliance scripts, require compliant device). Internal catalog codes are **not** used on slides.

### Slide map

1. Title  
2. Problem  
3. Recommendation  
4. Trust model (human / device / workload / network)  
5. Device trust chain  
6. What we are not building  
7. Phasing  
8. What we need from Identity and Access  
9. Success criteria  

Architecture: [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md)
