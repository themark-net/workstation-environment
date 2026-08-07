const pptxgen = require('pptxgenjs');

const pres = new pptxgen();
pres.defineLayout({ name: 'WIDE', width: 13.3333, height: 7.5 });
pres.layout = 'WIDE';
pres.title = 'Linux Zero Trust — Compliance-First';
pres.author = 'Linux Platform';
pres.subject = 'High-level architecture briefing';

const NAVY = '021F47';
const GOLD = 'DBA111';
const WHITE = 'FFFFFF';
const GRAY = '9CA3AF';
const DARK = '111827';
const BLUE = '034694';
const CREAM = 'F5F3EC';
const MUTED = '6B7280';

function footer(slide, n, total) {
  slide.addShape(pres.shapes.LINE, {
    x: 0.6, y: 7.05, w: 12.1, h: 0,
    line: { color: 'E5E7EB', width: 0.75 }
  });
  slide.addText('LINUX ZERO TRUST  |  INTERNAL', {
    x: 0.6, y: 7.15, w: 8, h: 0.25,
    fontSize: 10, color: MUTED, fontFace: 'Calibri', margin: 0
  });
  slide.addText(String(n).padStart(2, '0') + ' / ' + String(total).padStart(2, '0'), {
    x: 11.2, y: 7.15, w: 1.5, h: 0.25,
    fontSize: 10, color: MUTED, fontFace: 'Calibri', align: 'right', margin: 0
  });
}

const TOTAL = 9;

{
  const slide = pres.addSlide();
  slide.background = { color: NAVY };
  slide.addText('LINUX PLATFORM', {
    x: 0.7, y: 1.7, w: 11, h: 0.35,
    fontSize: 13, bold: true, color: GOLD, fontFace: 'Calibri', charSpacing: 5, margin: 0
  });
  slide.addText('Linux Zero Trust', {
    x: 0.7, y: 2.2, w: 12, h: 0.9,
    fontSize: 48, bold: true, color: WHITE, fontFace: 'Century Gothic', margin: 0
  });
  slide.addText('Compliance-first device trust on the existing Microsoft control plane', {
    x: 0.7, y: 3.2, w: 11.5, h: 0.5,
    fontSize: 22, italic: true, color: GRAY, fontFace: 'Century Gothic', margin: 0
  });
  slide.addShape(pres.shapes.LINE, {
    x: 0.7, y: 3.9, w: 4, h: 0,
    line: { color: GOLD, width: 2 }
  });
  slide.addText('High-level briefing for security architecture, IAM, and platform leadership', {
    x: 0.7, y: 4.2, w: 11, h: 0.4,
    fontSize: 14, color: GRAY, fontFace: 'Calibri', margin: 0
  });
  slide.addText('AUGUST 2026', {
    x: 0.7, y: 6.7, w: 4, h: 0.3,
    fontSize: 11, bold: true, color: GRAY, fontFace: 'Calibri', charSpacing: 3, margin: 0
  });
  slide.addText('INTERNAL  |  NOT FOR EXTERNAL DISTRIBUTION', {
    x: 6.5, y: 6.7, w: 6.2, h: 0.3,
    fontSize: 11, bold: true, color: GRAY, fontFace: 'Calibri', align: 'right', charSpacing: 2, margin: 0
  });
}

{
  const slide = pres.addSlide();
  slide.background = { color: WHITE };
  slide.addText('THE PROBLEM', {
    x: 0.6, y: 0.4, w: 12, h: 0.3,
    fontSize: 12, bold: true, color: GOLD, fontFace: 'Calibri', charSpacing: 3, margin: 0
  });
  slide.addText('Linux is treated as second-class for device trust', {
    x: 0.6, y: 0.8, w: 12, h: 0.55,
    fontSize: 28, bold: true, color: BLUE, fontFace: 'Century Gothic', margin: 0
  });
  const cards = [
    { t: 'Windows path is clear', d: 'Entra identity + Intune compliance + Conditional Access form a trusted device path architects already fund.' },
    { t: 'Linux user auth is done', d: 'SSSD OIDC to Entra with hybrid UID/GID already works. User login is not the gap.' },
    { t: 'Device health is not a CA signal', d: 'Without a Compliant bit, sensitive apps either block Linux or grant exceptions that weaken Zero Trust.' },
    { t: 'Passwordless is not the blocker', d: 'Hello-class CBA is desirable later. It does not unlock trusted Linux host decisions today.' }
  ];
  cards.forEach((c, i) => {
    const x = 0.6 + (i % 2) * 6.2;
    const y = 1.7 + Math.floor(i / 2) * 2.3;
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y, w: 5.9, h: 2.05, fill: { color: CREAM }, rectRadius: 0.08
    });
    slide.addShape(pres.shapes.RECTANGLE, {
      x, y, w: 0.1, h: 2.05, fill: { color: BLUE }
    });
    slide.addText(c.t, {
      x: x + 0.35, y: y + 0.3, w: 5.3, h: 0.4,
      fontSize: 18, bold: true, color: BLUE, fontFace: 'Century Gothic', margin: 0
    });
    slide.addText(c.d, {
      x: x + 0.35, y: y + 0.85, w: 5.3, h: 0.95,
      fontSize: 14, color: DARK, fontFace: 'Calibri', margin: 0
    });
  });
  footer(slide, 2, TOTAL);
}

{
  const slide = pres.addSlide();
  slide.background = { color: WHITE };
  slide.addText('RECOMMENDATION', {
    x: 0.6, y: 0.4, w: 12, h: 0.3,
    fontSize: 12, bold: true, color: GOLD, fontFace: 'Calibri', charSpacing: 3, margin: 0
  });
  slide.addText('One control plane — not a parallel Linux security stack', {
    x: 0.6, y: 0.8, w: 12, h: 0.55,
    fontSize: 26, bold: true, color: BLUE, fontFace: 'Century Gothic', margin: 0
  });
  slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
    x: 0.6, y: 1.6, w: 12.1, h: 1.5, fill: { color: NAVY }, rectRadius: 0.08
  });
  slide.addText('Fund a compliance-first program on Entra, Intune, and Conditional Access. Prove device trust first. Passwordless user UX and workload identity come after.', {
    x: 0.9, y: 1.9, w: 11.5, h: 0.9,
    fontSize: 18, color: WHITE, fontFace: 'Calibri', margin: 0
  });
  const cols = [
    { h: 'MVP', b: 'Thin attestor + compliance agent to Intune custom compliance to CA require compliant device' },
    { h: 'Future', b: 'Entra CBA / FIDO (no USB), AWX continuous policy, MS CA workload certs and optional SPIRE' },
    { h: 'Out of scope', b: 'Linux Autopilot, parallel IdP, Keycloak as Entra substitute, CBA as Intune attestation' }
  ];
  cols.forEach((c, i) => {
    const x = 0.6 + i * 4.15;
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y: 3.4, w: 3.95, h: 2.9, fill: { color: CREAM }, rectRadius: 0.08
    });
    slide.addText(c.h, {
      x: x + 0.25, y: 3.65, w: 3.45, h: 0.45,
      fontSize: 18, bold: true, color: GOLD, fontFace: 'Century Gothic', margin: 0
    });
    slide.addText(c.b, {
      x: x + 0.25, y: 4.25, w: 3.45, h: 1.8,
      fontSize: 15, color: DARK, fontFace: 'Calibri', margin: 0
    });
  });
  footer(slide, 3, TOTAL);
}

{
  const slide = pres.addSlide();
  slide.background = { color: WHITE };
  slide.addText('TRUST MODEL', {
    x: 0.6, y: 0.4, w: 12, h: 0.3,
    fontSize: 12, bold: true, color: GOLD, fontFace: 'Calibri', charSpacing: 3, margin: 0
  });
  slide.addText('Four planes — only device is the MVP critical path', {
    x: 0.6, y: 0.8, w: 12, h: 0.5,
    fontSize: 26, bold: true, color: BLUE, fontFace: 'Century Gothic', margin: 0
  });
  const planes = [
    { n: 'H', t: 'Human', s: 'DONE', d: 'SSSD OIDC to Entra\nFuture: TPM CBA / FIDO' },
    { n: 'D', t: 'Device', s: 'MVP', d: 'Attestor to ticket to\nIntune to CA compliant' },
    { n: 'W', t: 'Workload', s: 'FUTURE', d: 'MS CA intermediate\nOptional SPIRE' },
    { n: 'M', t: 'Management', s: 'MVP then F', d: 'Ansible client role now\nAWX continuous later' }
  ];
  planes.forEach((p, i) => {
    const x = 0.6 + i * 3.15;
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y: 1.6, w: 3.0, h: 4.6,
      fill: { color: i === 1 ? NAVY : CREAM }, rectRadius: 0.1
    });
    slide.addText(p.n, {
      x: x + 0.2, y: 1.85, w: 2.6, h: 0.55,
      fontSize: 28, bold: true, color: i === 1 ? GOLD : BLUE, fontFace: 'Century Gothic', margin: 0
    });
    slide.addText(p.t, {
      x: x + 0.2, y: 2.5, w: 2.6, h: 0.45,
      fontSize: 20, bold: true, color: i === 1 ? WHITE : BLUE, fontFace: 'Century Gothic', margin: 0
    });
    slide.addText(p.s, {
      x: x + 0.2, y: 3.1, w: 2.6, h: 0.35,
      fontSize: 13, bold: true, color: GOLD, fontFace: 'Calibri', charSpacing: 2, margin: 0
    });
    slide.addText(p.d, {
      x: x + 0.2, y: 3.7, w: 2.6, h: 2.0,
      fontSize: 15, color: i === 1 ? GRAY : DARK, fontFace: 'Calibri', margin: 0
    });
  });
  footer(slide, 4, TOTAL);
}

{
  const slide = pres.addSlide();
  slide.background = { color: WHITE };
  slide.addText('MVP DEVICE CHAIN', {
    x: 0.6, y: 0.4, w: 12, h: 0.3,
    fontSize: 12, bold: true, color: GOLD, fontFace: 'Calibri', charSpacing: 3, margin: 0
  });
  slide.addText('Attestor-backed compliance — fail closed without a ticket', {
    x: 0.6, y: 0.8, w: 12, h: 0.5,
    fontSize: 24, bold: true, color: BLUE, fontFace: 'Century Gothic', margin: 0
  });
  const steps = [
    { n: '01', t: 'Enroll', d: 'Lab birth record or Intune enroll' },
    { n: '02', t: 'Attest', d: 'Thin attestor verifies evidence' },
    { n: '03', t: 'Ticket', d: 'Short-lived device credential' },
    { n: '04', t: 'Report', d: 'Agent posts only with ticket' },
    { n: '05', t: 'Compliant', d: 'Intune custom rules evaluate' },
    { n: '06', t: 'Access', d: 'CA requires compliant device' }
  ];
  steps.forEach((s, i) => {
    const x = 0.5 + i * 2.15;
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x, y: 2.0, w: 2.0, h: 3.6, fill: { color: CREAM }, rectRadius: 0.08
    });
    slide.addText(s.n, {
      x: x + 0.15, y: 2.25, w: 1.7, h: 0.4,
      fontSize: 16, bold: true, color: GOLD, fontFace: 'Century Gothic', margin: 0
    });
    slide.addText(s.t, {
      x: x + 0.15, y: 2.9, w: 1.7, h: 0.5,
      fontSize: 18, bold: true, color: BLUE, fontFace: 'Century Gothic', margin: 0
    });
    slide.addText(s.d, {
      x: x + 0.15, y: 3.6, w: 1.7, h: 1.6,
      fontSize: 14, color: DARK, fontFace: 'Calibri', margin: 0
    });
  });
  footer(slide, 5, TOTAL);
}

{
  const slide = pres.addSlide();
  slide.background = { color: WHITE };
  slide.addText('WHAT WE ARE NOT BUILDING', {
    x: 0.6, y: 0.4, w: 12, h: 0.3,
    fontSize: 12, bold: true, color: GOLD, fontFace: 'Calibri', charSpacing: 3, margin: 0
  });
  slide.addText('Avoid parallel islands and dishonest claims', {
    x: 0.6, y: 0.8, w: 12, h: 0.5,
    fontSize: 26, bold: true, color: BLUE, fontFace: 'Century Gothic', margin: 0
  });
  const rejects = [
    ['Fake Autopilot for Linux', 'No Linux ZTD client; wrong protocol'],
    ['Parallel Linux-only IdP', 'Splits CA; weaker Microsoft integration'],
    ['CBA as device attestation', 'User auth plane is not Intune compliance'],
    ['Trust local status.json alone', 'Forgeable without attestor tickets'],
    ['USB keys for daily passwordless', 'Breaks Hello-class UX parity'],
    ['Block MVP on CBA tickets', 'Wrong dependency; delays compliance']
  ];
  rejects.forEach((r, i) => {
    const y = 1.55 + i * 0.8;
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: 0.6, y, w: 12.1, h: 0.7, fill: { color: CREAM }, rectRadius: 0.06
    });
    slide.addText(r[0], {
      x: 0.9, y: y + 0.15, w: 5.5, h: 0.4,
      fontSize: 16, bold: true, color: BLUE, fontFace: 'Calibri', margin: 0
    });
    slide.addText(r[1], {
      x: 6.6, y: y + 0.15, w: 5.8, h: 0.4,
      fontSize: 15, color: DARK, fontFace: 'Calibri', margin: 0
    });
  });
  footer(slide, 6, TOTAL);
}

{
  const slide = pres.addSlide();
  slide.background = { color: WHITE };
  slide.addText('PHASING', {
    x: 0.6, y: 0.4, w: 12, h: 0.3,
    fontSize: 12, bold: true, color: GOLD, fontFace: 'Calibri', charSpacing: 3, margin: 0
  });
  slide.addText('MVP first — Future does not block engineering', {
    x: 0.6, y: 0.8, w: 12, h: 0.5,
    fontSize: 26, bold: true, color: BLUE, fontFace: 'Century Gothic', margin: 0
  });
  const phases = [
    { p: 'M0', t: 'Foundations', d: 'Lab MVP, repo boundaries, RACI', h: '1 to 2 wk' },
    { p: 'M1', t: 'Device trust', d: 'Attestor, agent, collector, Intune artifacts', h: '4 to 6 wk' },
    { p: 'M2', t: 'Tenant plug-in', d: 'REQ-M Intune + CA compliant device', h: 'IAM-gated' },
    { p: 'F1', t: 'User CBA / FIDO', d: 'Hello-class passwordless (no USB)', h: 'After M2' },
    { p: 'F2', t: 'AWX depth', d: 'Continuous policy (GPO-class)', h: 'Parallel' },
    { p: 'F3', t: 'Workload ID', d: 'MS CA optional SPIRE', h: 'After M2' }
  ];
  phases.forEach((ph, i) => {
    const y = 1.5 + i * 0.85;
    const isMvp = i < 3;
    slide.addShape(pres.shapes.ROUNDED_RECTANGLE, {
      x: 0.6, y, w: 1.4, h: 0.7,
      fill: { color: isMvp ? NAVY : CREAM }, rectRadius: 0.06
    });
    slide.addText(ph.p, {
      x: 0.6, y: y + 0.15, w: 1.4, h: 0.4,
      fontSize: 16, bold: true, color: isMvp ? GOLD : BLUE, fontFace: 'Century Gothic', align: 'center', margin: 0
    });
    slide.addText(ph.t, {
      x: 2.2, y: y + 0.15, w: 3.2, h: 0.4,
      fontSize: 16, bold: true, color: BLUE, fontFace: 'Calibri', margin: 0
    });
    slide.addText(ph.d, {
      x: 5.5, y: y + 0.15, w: 5.0, h: 0.4,
      fontSize: 15, color: DARK, fontFace: 'Calibri', margin: 0
    });
    slide.addText(ph.h, {
      x: 10.7, y: y + 0.15, w: 2.0, h: 0.4,
      fontSize: 14, color: MUTED, fontFace: 'Calibri', align: 'right', margin: 0
    });
  });
  footer(slide, 7, TOTAL);
}

{
  const slide = pres.addSlide();
  slide.background = { color: WHITE };
  slide.addText('THE ASK', {
    x: 0.6, y: 0.4, w: 12, h: 0.3,
    fontSize: 12, bold: true, color: GOLD, fontFace: 'Calibri', charSpacing: 3, margin: 0
  });
  slide.addText('Approve MVP engineering and prioritize REQ-M', {
    x: 0.6, y: 0.8, w: 12, h: 0.5,
    fontSize: 26, bold: true, color: BLUE, fontFace: 'Century Gothic', margin: 0
  });
  const asks = [
    { n: '1', t: 'Approve MVP engineering', d: 'Attestor, client agent, lab evidence, Intune discovery and rules artifacts. About 200 to 320 hours planning estimate.' },
    { n: '2', t: 'Prioritize REQ-M IAM tickets', d: 'Intune Linux enroll, custom compliance, Conditional Access require compliant device (report-only then on).' },
    { n: '3', t: 'Defer REQ-F (CBA) until pilot is green', d: 'Unless org-wide phishing-resistant MFA already mandates it for all platforms.' }
  ];
  asks.forEach((a, i) => {
    const y = 1.6 + i * 1.6;
    slide.addShape(pres.shapes.OVAL, {
      x: 0.7, y: y + 0.15, w: 0.7, h: 0.7, fill: { color: NAVY }
    });
    slide.addText(a.n, {
      x: 0.7, y: y + 0.28, w: 0.7, h: 0.45,
      fontSize: 20, bold: true, color: GOLD, fontFace: 'Century Gothic', align: 'center', margin: 0
    });
    slide.addText(a.t, {
      x: 1.7, y: y, w: 10.5, h: 0.45,
      fontSize: 20, bold: true, color: BLUE, fontFace: 'Century Gothic', margin: 0
    });
    slide.addText(a.d, {
      x: 1.7, y: y + 0.55, w: 10.5, h: 0.7,
      fontSize: 15, color: DARK, fontFace: 'Calibri', margin: 0
    });
  });
  footer(slide, 8, TOTAL);
}

{
  const slide = pres.addSlide();
  slide.background = { color: NAVY };
  slide.addText('SUCCESS LOOKS LIKE', {
    x: 0.7, y: 1.3, w: 12, h: 0.35,
    fontSize: 13, bold: true, color: GOLD, fontFace: 'Calibri', charSpacing: 4, margin: 0
  });
  slide.addText('Pilot Linux hosts show Compliant.\nConditional Access grants or denies on that bit.\nFail-closed without a valid attestation ticket.\nClient code ships without lab dependencies.', {
    x: 0.7, y: 2.0, w: 11.5, h: 3.2,
    fontSize: 26, color: WHITE, fontFace: 'Century Gothic', margin: 0
  });
  slide.addText('Architecture and lab: workstation-environment  ·  REQ catalog: REQ-M / REQ-F', {
    x: 0.7, y: 6.5, w: 11.5, h: 0.35,
    fontSize: 13, color: GRAY, fontFace: 'Calibri', margin: 0
  });
}

const out = process.env.OUT || 'Linux-Zero-Trust-Briefing.pptx';
pres.writeFile({ fileName: out })
  .then(() => console.log('Wrote', out))
  .catch((e) => { console.error(e); process.exit(1); });
