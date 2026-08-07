const pptxgen = require('pptxgenjs');

// Visual reference: EMSL Brand & Style Guide (Oct 2025) public PDF —
// primary navy #11134A, science blue #1C83C9. Body text black on white.
// Full corporate PNNL .pptx templates are not publicly downloadable;
// this approximates that lab style for internal briefing use.

const pres = new pptxgen();
pres.defineLayout({ name: 'WIDE', width: 13.3333, height: 7.5 });
pres.layout = 'WIDE';
pres.title = 'Linux Zero Trust — Compliance-First';
pres.author = 'Linux Platform';
pres.subject = 'High-level architecture briefing';

const NAVY = '11134A';
const BLUE = '1C83C9';
const BLACK = '000000';
const WHITE = 'FFFFFF';
const LIGHT = 'F3F4F6';
const GRAY = '4B5563';
const MUTED = '6B7280';

function footer(slide, n, total) {
  slide.addShape(pres.shapes.LINE, {
    x: 0.6, y: 7.05, w: 12.1, h: 0,
    line: { color: 'D1D5DB', width: 0.75 }
  });
  slide.addText('Linux Zero Trust  |  Internal briefing', {
    x: 0.6, y: 7.15, w: 9, h: 0.25,
    fontSize: 10, color: MUTED, fontFace: 'Arial', margin: 0
  });
  slide.addText(String(n) + ' / ' + String(total), {
    x: 11.0, y: 7.15, w: 1.7, h: 0.25,
    fontSize: 10, color: MUTED, fontFace: 'Arial', align: 'right', margin: 0
  });
}

const TOTAL = 9;

{
  const slide = pres.addSlide();
  slide.background = { color: NAVY };
  slide.addText('LINUX PLATFORM', {
    x: 0.7, y: 1.8, w: 11, h: 0.35,
    fontSize: 14, bold: true, color: BLUE, fontFace: 'Arial', charSpacing: 3, margin: 0
  });
  slide.addText('Linux Zero Trust', {
    x: 0.7, y: 2.3, w: 12, h: 0.85,
    fontSize: 44, bold: true, color: WHITE, fontFace: 'Arial', margin: 0
  });
  slide.addText('Device compliance first — on the existing Microsoft control plane', {
    x: 0.7, y: 3.25, w: 11.5, h: 0.45,
    fontSize: 20, color: 'D1D5DB', fontFace: 'Arial', margin: 0
  });
  slide.addShape(pres.shapes.LINE, {
    x: 0.7, y: 3.9, w: 3.5, h: 0,
    line: { color: BLUE, width: 2 }
  });
  slide.addText('Briefing for security architecture, identity, and platform leadership', {
    x: 0.7, y: 4.2, w: 11, h: 0.35,
    fontSize: 14, color: '9CA3AF', fontFace: 'Arial', margin: 0
  });
  slide.addText('August 2026', {
    x: 0.7, y: 6.7, w: 4, h: 0.3,
    fontSize: 12, color: '9CA3AF', fontFace: 'Arial', margin: 0
  });
  slide.addText('Internal use only', {
    x: 8.5, y: 6.7, w: 4.2, h: 0.3,
    fontSize: 12, color: '9CA3AF', fontFace: 'Arial', align: 'right', margin: 0
  });
}

// remaining slides loaded from artifacts build — see full file in CI
const out = process.env.OUT || 'Linux-Zero-Trust-Briefing.pptx';
console.log('Stub: use full ltz-deck.js from artifacts or regenerate from conversation');
