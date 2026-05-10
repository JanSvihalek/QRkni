// Generates QRkni logo PNGs at multiple sizes from inline SVG.
//
// Usage:
//   cd tool
//   npm install sharp
//   node generate_icons.js
//
// Outputs to ../assets/icons/

const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const BRAND = '#1652F0';
const INK = '#0A1330';

const SIZES = [16, 32, 64, 128, 256, 512, 1024];

// SVG of the logo mark (Scan Brackets) — viewBox is 100x100, scales to any size.
function logoMarkSvg(color) {
  const s = 100;
  const stroke = s * 0.085;
  const corner = s * 0.32;
  const r = s * 0.14;
  const c = s * 0.5;
  const m = s * 0.085;
  const gap = m * 1.35;

  const positions = [
    [-1, -1], [0, -1], [1, -1],
    [-1, 0],            [1, 0],
    [-1, 1], [0, 1], [1, 1],
  ];

  const dots = positions.map(([dx, dy]) => {
    const x = c + dx * gap - m / 2;
    const y = c + dy * gap - m / 2;
    return `<rect x="${x}" y="${y}" width="${m}" height="${m}" rx="${m * 0.22}" fill="${color}"/>`;
  }).join('');

  const tl = `M ${stroke / 2} ${r + corner} V ${r + stroke / 2} A ${r} ${r} 0 0 1 ${r + stroke / 2} ${stroke / 2} H ${corner + stroke / 2}`;
  const tr = `M ${s - corner - stroke / 2} ${stroke / 2} H ${s - r - stroke / 2} A ${r} ${r} 0 0 1 ${s - stroke / 2} ${r + stroke / 2} V ${corner + stroke / 2}`;
  const bl = `M ${stroke / 2} ${s - corner - stroke / 2} V ${s - r - stroke / 2} A ${r} ${r} 0 0 0 ${r + stroke / 2} ${s - stroke / 2} H ${corner + stroke / 2}`;
  const br = `M ${s - corner - stroke / 2} ${s - stroke / 2} H ${s - r - stroke / 2} A ${r} ${r} 0 0 0 ${s - stroke / 2} ${s - r - stroke / 2} V ${s - corner - stroke / 2}`;

  const stroked = (d) => `<path d="${d}" stroke="${color}" stroke-width="${stroke}" fill="none" stroke-linecap="round"/>`;

  return `${stroked(tl)}${stroked(tr)}${stroked(bl)}${stroked(br)}${dots}`;
}

function brandLogoSvg() {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">${logoMarkSvg(BRAND)}</svg>`;
}

function whiteOnInkSvg() {
  // White mark on dark ink square (for dark contexts)
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
    <rect width="100" height="100" fill="${INK}"/>
    <g transform="translate(11, 11) scale(0.78)">${logoMarkSvg('#FFFFFF')}</g>
  </svg>`;
}

function whiteTransparentSvg() {
  // White mark on transparent — for splash and dark overlays
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">${logoMarkSvg('#FFFFFF')}</svg>`;
}

function appIconSvg() {
  // Rounded blue square + white mark inside (~62% size)
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
    <rect width="100" height="100" rx="22" fill="${BRAND}"/>
    <g transform="translate(19, 19) scale(0.62)">${logoMarkSvg('#FFFFFF')}</g>
  </svg>`;
}

function launcherSourceSvg() {
  // Square full-bleed blue + white mark — flutter_launcher_icons rounds per platform
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
    <rect width="100" height="100" fill="${BRAND}"/>
    <g transform="translate(19, 19) scale(0.62)">${logoMarkSvg('#FFFFFF')}</g>
  </svg>`;
}

async function renderToFile(svgString, size, outPath) {
  await sharp(Buffer.from(svgString), { density: 2400 })
    .resize(size, size)
    .png({ compressionLevel: 9 })
    .toFile(outPath);
}

async function main() {
  const outDir = path.resolve(__dirname, '..', 'assets', 'icons');
  fs.mkdirSync(outDir, { recursive: true });

  const variants = [
    { id: 'brand', svg: brandLogoSvg() },
    { id: 'white', svg: whiteOnInkSvg() },
    { id: 'icon',  svg: appIconSvg() },
    { id: 'white-transparent', svg: whiteTransparentSvg() },
  ];

  for (const v of variants) {
    for (const size of SIZES) {
      const out = path.join(outDir, `qrkni-${v.id}-${size}.png`);
      await renderToFile(v.svg, size, out);
      console.log(`✓ ${path.relative(process.cwd(), out)}`);
    }
  }

  // Launcher source
  const launcherOut = path.join(outDir, 'qrkni-launcher-source-1024.png');
  await renderToFile(launcherSourceSvg(), 1024, launcherOut);
  console.log(`✓ ${path.relative(process.cwd(), launcherOut)}`);

  // Save the master SVGs too (handy for vector use)
  for (const v of variants) {
    const svgOut = path.join(outDir, `qrkni-${v.id}.svg`);
    fs.writeFileSync(svgOut, v.svg);
    console.log(`✓ ${path.relative(process.cwd(), svgOut)}`);
  }

  console.log('\nDone — check assets/icons/');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
