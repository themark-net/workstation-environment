# Presentations

## Linux Zero Trust — Compliance-First Briefing

High-level deck for security architecture, IAM, and platform leadership.

| File | Role |
|------|------|
| `Linux-Zero-Trust-Briefing.pptx` | Built slides (regenerate from script if missing) |
| `ltz-deck.js` | PptxGenJS source — source of truth for content |

### Regenerate

```bash
npm install pptxgenjs
node docs/presentations/ltz-deck.js
# writes Linux-Zero-Trust-Briefing.pptx (adjust path in script if needed)
```

### Slide map

1. Title — compliance-first on Microsoft control plane  
2. Problem — device health not a CA signal  
3. Recommendation — one plane, MVP vs Future  
4. Trust model — planes H / D / W / M  
5. MVP device chain — enroll → attest → ticket → compliant → CA  
6. What we are not building  
7. Phasing M0–M2 / F1–F3  
8. The ask — MVP + REQ-M  
9. Success criteria  

Canonical architecture: [../architecture/MVP-AND-FUTURE-STATE.md](../architecture/MVP-AND-FUTURE-STATE.md)
