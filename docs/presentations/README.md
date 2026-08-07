# Presentations

## Linux Zero Trust — Compliance-First Briefing

High-level deck for security architecture, identity, and platform leadership.

### Build the deck

```bash
npm install pptxgenjs
# Use the full generator from a local copy of ltz-deck.js (see below)
OUT=./Linux-Zero-Trust-Briefing.pptx node ltz-deck.js
```

The checked-in `ltz-deck.js` may be a thin assembler; the **authoritative full script** is the 9-slide generator with:

- **Body text:** black (`#000000`) on white content slides  
- **Title / accent:** navy `#11134A`, blue `#1C83C9` (from the public **EMSL Brand & Style Guide, October 2025** — EMSL is a PNNL user facility). A public corporate PNNL `.pptx` template for the last year was **not** found for download; use your lab Organizational Asset Library / brand kit for official external briefings.  
- **Font:** Arial  
- **IAM language:** plain English only (no internal ticket codes such as REQ-M / REQ-F)

### IAM asks on the deck (slide 8)

1. Allow Linux devices to enroll in Intune (pilot group + licenses)  
2. Accept the Linux custom compliance discovery script and rules  
3. Require a compliant device for pilot apps (report-only, then enforce; break-glass)  
4. Hold passwordless user work until after the device pilot (unless already required org-wide)

### Slide map

1. Title  
2. Problem  
3. Recommendation  
4. Trust model  
5. Device trust chain  
6. What we are not building  
7. Phasing  
8. What we need from Identity and Access  
9. Success criteria  

Architecture: [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md)
