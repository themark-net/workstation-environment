#!/usr/bin/env node
/**
 * Linux Zero Trust briefing — PPTX generator
 *
 * CONTENT: edit briefing.yaml (preferred) or briefing.json
 * BUILD:   npm install pptxgenjs && node ltz-deck.js
 *          optional: npm install js-yaml  (to read .yaml)
 * OUTPUT:  Linux-Zero-Trust-Briefing.pptx  (or OUT=path)
 *
 * Keep slide copy in the content file — not in this script.
 */

const fs = require('fs');
const path = require('path');
const pptxgen = require('pptxgenjs');

const root = __dirname;

function loadContent() {
  const yamlPath = path.join(root, 'briefing.yaml');
  const jsonPath = path.join(root, 'briefing.json');

  if (fs.existsSync(yamlPath)) {
    try {
      const yaml = require('js-yaml');
      return yaml.load(fs.readFileSync(yamlPath, 'utf8'));
    } catch (e) {
      if (e.code !== 'MODULE_NOT_FOUND') throw e;
    }
  }
  if (fs.existsSync(jsonPath)) {
    return JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  }
  console.error('Missing briefing.yaml or briefing.json next to ltz-deck.js');
  process.exit(1);
}

const doc = loadContent();
const t = Object.assign({
  navy: '11134A',
  blue: '1C83C9',
  black: '000000',
  white: 'FFFFFF',
  light: 'F3F4F6',
  gray: '4B5563',
  muted: '6B7280',
}, doc.theme || {});

const meta = doc.meta || {};
const slides = doc.slides || [];

const pres = new pptxgen();
pres.defineLayout({ name: 'WIDE', width: 13.3333, height: 7.5 });
pres.layout = 'WIDE';
pres.title = meta.title || 'Linux Zero Trust';
pres.author = meta.author || 'Linux Platform';

function footer(slide, n, total) {
  slide.addShape(pres.shapes.LINE, {
    x: 0.6, y: 7.05, w: 12.1, h: 0,
    line: { color: 'D1D5DB', width: 0.75 },
  });
  slide.addText(meta.footer || 'Linux Zero Trust', {
    x: 0.6, y: 7.15, w: 9, h: 0.25,
    fontSize: 10, color: t.muted, fontFace: 'Arial', margin: 0,
  });
  slide.addText(String(n) + ' / ' + String(total), {
    x: 11.0, y: 7.15, w: 1.7, h: 0.25,
    fontSize: 10, color: t.muted, fontFace: 'Arial', align: 'right', margin: 0,
  });
}

const TOTAL = slides.length;

slides.forEach((s, idx) => {
  const n = idx + 1;
  const slide = pres.addSlide();

  if (s.type === 'title') {
    slide.background = { color: t.navy };
    slide.addText(s.kicker || '', {
      x: 0.7, y: 1.8, w: 11, h: 0.35,
      fontSize: 14, bold: true, color: t.blue, fontFace: 'Arial', charSpacing: 3, margin: 0,
    });
    slide.addText(s.title || '', {
      x: 0.7, y: 2.3, w: 12, h: 0.85,
      fontSize: 44, bold: true, color: t.white, fontFace: 'Arial', margin: 0,
    });
    slide.addText(s.subtitle || '', {
      x: 0.7, y: 3.25, w: 11.5, h: 0.45,
      fontSize: 20, color: 'D1D5DB', fontFace: 'Arial', margin: 0,
    });
    slide.addShape(pres.shapes.LINE, {
      x: 0.7, y: 3.9, w: 3.5, h: 0, line: { color: t.blue, width: 2 },
    });
    slide.addText(s.line || '', {
      x: 0.7, y: 4.2, w: 11, h: 0.35,
      fontSize: 14, color: '9CA3AF', fontFace: 'Arial', margin: 0,
    });
    slide.addText(meta.date || '', {
      x: 0.7, y: 6.7, w: 4, h: 0.3,
      fontSize: 12, color: '9CA3AF', fontFace: 'Arial', margin: 0,
    });
    slide.addText(meta.classification || '', {
      x: 8.5, y: 6.7, w: 4.2, h: 0.3,
      fontSize: 12, color: '9CA3AF', fontFace: 'Arial', align: 'right', margin: 0,
    });
    return;
  }

  slide.background = { color: t.white };

  if (s.section) {
    slide.addText(s.section, {
      x: 0.6, y: 0.35, w: 12, h: 0.3,
      fontSize: 12, bold: true, color: t.blue, fontFace: 'Arial', charSpacing: 2, margin: 0,
    });
  }
  if (s.title && s.type !== 'success') {
    slide.addText(s.title, {
      x: 0.6, y: 0.7, w: 12, h: 0.5,
      fontSize: s.type === 'steps' ? 22 : 24, bold: true, color: t.black, fontFace: 'Arial', margin: 0,
    });
  }

  if (s.type === 'cards') {
    (s.cards || []).forEach((c, i) => {
      const x = 0.6 + (i % 2) * 6.2;
      const y = 1.5 + Math.floor(i / 2) * 2.45;
      slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
        x, y, w: 5.9, h: 2.25, fill: { color: t.light }, rectRadius: 0.06,
      });
      slide.addShape(pres.shapes.RECTANGLE, {
        x, y, w: 0.1, h: 2.25, fill: { color: t.navy },
      });
      slide.addText(c.title, {
        x: x + 0.35, y: y + 0.3, w: 5.3, h: 0.4,
        fontSize: 18, bold: true, color: t.black, fontFace: 'Arial', margin: 0,
      });
      slide.addText(c.body, {
        x: x + 0.35, y: y + 0.85, w: 5.3, h: 1.1,
        fontSize: 15, color: t.black, fontFace: 'Arial', margin: 0,
      });
    });
  }

  if (s.type === 'recommendation') {
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: 0.6, y: 1.45, w: 12.1, h: 1.35, fill: { color: t.light }, rectRadius: 0.06,
    });
    slide.addText(s.banner || '', {
      x: 0.9, y: 1.7, w: 11.5, h: 0.9,
      fontSize: 16, color: t.black, fontFace: 'Arial', margin: 0,
    });
    (s.columns || []).forEach((c, i) => {
      const x = 0.6 + i * 4.15;
      slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
        x, y: 3.1, w: 3.95, h: 3.15, fill: { color: t.light }, rectRadius: 0.06,
      });
      slide.addText(c.title, {
        x: x + 0.25, y: 3.35, w: 3.45, h: 0.45,
        fontSize: 17, bold: true, color: t.navy, fontFace: 'Arial', margin: 0,
      });
      slide.addText(c.body, {
        x: x + 0.25, y: 3.95, w: 3.45, h: 2.0,
        fontSize: 15, color: t.black, fontFace: 'Arial', margin: 0,
      });
    });
  }

  if (s.type === 'planes') {
    (s.planes || []).forEach((p, i) => {
      const x = 0.6 + i * 3.15;
      const hi = !!p.highlight;
      slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
        x, y: 1.5, w: 3.0, h: 4.7,
        fill: { color: hi ? t.navy : t.light }, rectRadius: 0.08,
      });
      slide.addText(String(p.number), {
        x: x + 0.2, y: 1.75, w: 2.6, h: 0.45,
        fontSize: 22, bold: true, color: hi ? t.blue : t.navy, fontFace: 'Arial', margin: 0,
      });
      slide.addText(p.title, {
        x: x + 0.2, y: 2.35, w: 2.6, h: 0.45,
        fontSize: 20, bold: true, color: hi ? t.white : t.black, fontFace: 'Arial', margin: 0,
      });
      slide.addText(p.status, {
        x: x + 0.2, y: 2.95, w: 2.6, h: 0.35,
        fontSize: 13, bold: true, color: hi ? t.blue : t.navy, fontFace: 'Arial', margin: 0,
      });
      slide.addText(p.body, {
        x: x + 0.2, y: 3.55, w: 2.6, h: 2.2,
        fontSize: 15, color: hi ? 'E5E7EB' : t.black, fontFace: 'Arial', margin: 0,
      });
    });
  }

  if (s.type === 'steps') {
    (s.steps || []).forEach((st, i) => {
      const x = 0.5 + i * 2.15;
      slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
        x, y: 1.85, w: 2.0, h: 4.3, fill: { color: t.light }, rectRadius: 0.06,
      });
      slide.addText(String(st.number), {
        x: x + 0.15, y: 2.1, w: 1.7, h: 0.4,
        fontSize: 18, bold: true, color: t.navy, fontFace: 'Arial', margin: 0,
      });
      slide.addText(st.title, {
        x: x + 0.15, y: 2.7, w: 1.7, h: 0.5,
        fontSize: 17, bold: true, color: t.black, fontFace: 'Arial', margin: 0,
      });
      slide.addText(st.body, {
        x: x + 0.15, y: 3.4, w: 1.7, h: 2.3,
        fontSize: 14, color: t.black, fontFace: 'Arial', margin: 0,
      });
    });
  }

  if (s.type === 'reject_list') {
    (s.items || []).forEach((it, i) => {
      const y = 1.45 + i * 0.82;
      slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
        x: 0.6, y, w: 12.1, h: 0.72, fill: { color: t.light }, rectRadius: 0.05,
      });
      slide.addText(it.left, {
        x: 0.9, y: y + 0.18, w: 5.5, h: 0.4,
        fontSize: 15, bold: true, color: t.black, fontFace: 'Arial', margin: 0,
      });
      slide.addText(it.right, {
        x: 6.6, y: y + 0.18, w: 5.8, h: 0.4,
        fontSize: 15, color: t.black, fontFace: 'Arial', margin: 0,
      });
    });
  }

  if (s.type === 'phases') {
    (s.phases || []).forEach((ph, i) => {
      const y = 1.4 + i * 0.85;
      const early = !!ph.early;
      slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
        x: 0.6, y, w: 1.3, h: 0.7,
        fill: { color: early ? t.navy : t.light }, rectRadius: 0.05,
      });
      slide.addText(String(ph.number), {
        x: 0.6, y: y + 0.15, w: 1.3, h: 0.4,
        fontSize: 18, bold: true, color: early ? t.white : t.navy, fontFace: 'Arial', align: 'center', margin: 0,
      });
      slide.addText(ph.title, {
        x: 2.15, y: y + 0.15, w: 3.4, h: 0.4,
        fontSize: 16, bold: true, color: t.black, fontFace: 'Arial', margin: 0,
      });
      slide.addText(ph.detail, {
        x: 5.6, y: y + 0.15, w: 5.0, h: 0.4,
        fontSize: 15, color: t.black, fontFace: 'Arial', margin: 0,
      });
      slide.addText(ph.timing, {
        x: 10.7, y: y + 0.15, w: 2.0, h: 0.4,
        fontSize: 14, color: t.gray, fontFace: 'Arial', align: 'right', margin: 0,
      });
    });
  }

  if (s.type === 'numbered_asks') {
    (s.asks || []).forEach((a, i) => {
      const y = 1.25 + i * 1.35;
      slide.addShape(pres.shapes.OVAL, {
        x: 0.7, y: y + 0.1, w: 0.55, h: 0.55, fill: { color: t.navy },
      });
      slide.addText(String(a.number), {
        x: 0.7, y: y + 0.2, w: 0.55, h: 0.4,
        fontSize: 16, bold: true, color: t.white, fontFace: 'Arial', align: 'center', margin: 0,
      });
      slide.addText(a.title, {
        x: 1.5, y: y, w: 11, h: 0.4,
        fontSize: 17, bold: true, color: t.black, fontFace: 'Arial', margin: 0,
      });
      slide.addText(a.body, {
        x: 1.5, y: y + 0.45, w: 11, h: 0.55,
        fontSize: 14, color: t.black, fontFace: 'Arial', margin: 0,
      });
    });
  }

  if (s.type === 'success') {
    slide.addText(s.section || 'SUCCESS LOOKS LIKE', {
      x: 0.7, y: 1.4, w: 12, h: 0.35,
      fontSize: 12, bold: true, color: t.blue, fontFace: 'Arial', charSpacing: 2, margin: 0,
    });
    slide.addText(s.body || '', {
      x: 0.7, y: 2.0, w: 11.5, h: 3.0,
      fontSize: 24, color: t.black, fontFace: 'Arial', margin: 0,
    });
    if (s.note) {
      slide.addText(s.note, {
        x: 0.7, y: 5.5, w: 11.5, h: 0.4,
        fontSize: 14, color: t.gray, fontFace: 'Arial', margin: 0,
      });
    }
  }

  if (s.type !== 'title') footer(slide, n, TOTAL);
});

const out = process.env.OUT || path.join(root, 'Linux-Zero-Trust-Briefing.pptx');
pres.writeFile({ fileName: out })
  .then(() => console.log('Wrote', out, '(' + TOTAL + ' slides from content file)'))
  .catch((e) => { console.error(e); process.exit(1); });
