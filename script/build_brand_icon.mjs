#!/usr/bin/env node
// Gera o selo da marca consumido como favicon / app icon.
//
// A marca é uma só: quadrado com o gradiente `primary`, carregando o glifo
// `bi-cash-coin` em `on-primary` — exatamente a composição de `.app-brand__icon`
// (app/assets/stylesheets/app_shell.scss). O glifo vem do próprio pacote
// `bootstrap-icons`, para o ícone do produto e o da topbar nunca divergirem.
//
// Este script existe porque PNG não se edita à mão: sem ele, os assets em
// `public/` viram binários órfãos que ninguém sabe reproduzir.
//
//   node script/build_brand_icon.mjs
//
import { chromium } from "playwright";
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const GLYPH = join(ROOT, "node_modules/bootstrap-icons/icons/cash-coin.svg");

// Tokens do DESIGN-SYSTEM.md. Manter em sincronia com
// app/assets/stylesheets/design_system/_tokens.scss.
const PRIMARY = "#0FA968"; // --color-primary       (mint-600)
const PRIMARY_HOVER = "#10B981"; // --color-primary-hover (mint-500)
const ON_PRIMARY = "#06251A"; // --color-on-primary

// O raio do selo é proporcional ao quadro, e não o `--radius-md` do selo da
// topbar: `--radius-md` (12px) é um token amarrado ao tamanho daquele elemento
// de 34px. Escalá-lo até 512px daria 35% e o quadrado viraria um blob. 22,4% é
// o raio de squircle que o iOS usa, então o ícone se comporta bem quando o
// sistema aplica a máscara dele.
const RADIUS_RATIO = 0.224;

// O glifo é desenhado num viewBox 16x16. 58% é o maior valor que ainda deixa
// respiro nas quinas sem o `$` encostar na borda; abaixo disso ele deixa de ser
// legível a 32px, que é o menor tamanho em que a marca ainda se lê.
const GLYPH_RATIO = 0.58;

const VIEWBOX = 512;
const paths = [
  ...readFileSync(GLYPH, "utf8").matchAll(/<path\b[^>]*\/>/g),
].map((m) => m[0]);

/** Monta o selo. `bleed: true` preenche o quadro inteiro (para o iOS mascarar). */
function seal({ bleed = false } = {}) {
  const rx = bleed ? 0 : Math.round(VIEWBOX * RADIUS_RATIO);
  const glyph = VIEWBOX * GLYPH_RATIO;
  const scale = +(glyph / 16).toFixed(4);
  const offset = +((VIEWBOX - glyph) / 2).toFixed(2);
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${VIEWBOX} ${VIEWBOX}" width="${VIEWBOX}" height="${VIEWBOX}" role="img" aria-label="Despesas Caviso">
  <defs>
    <linearGradient id="brand-seal" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${PRIMARY}"/>
      <stop offset="1" stop-color="${PRIMARY_HOVER}"/>
    </linearGradient>
  </defs>
  <rect width="${VIEWBOX}" height="${VIEWBOX}" rx="${rx}" fill="url(#brand-seal)"/>
  <g transform="translate(${offset} ${offset}) scale(${scale})" fill="${ON_PRIMARY}">
${paths.map((p) => "    " + p).join("\n")}
  </g>
</svg>
`;
}

const targets = [
  {
    file: "public/icon.svg",
    svg: seal(),
    note: "fonte vetorial — cantos arredondados e transparentes",
  },
  {
    file: "public/icon.png",
    svg: seal(),
    px: 512,
    note: "fallback de navegadores sem SVG — mesmo desenho do icon.svg",
  },
  {
    // O iOS aplica a própria máscara e compõe fundo preto onde houver
    // transparência. Uma imagem sangrada e opaca evita as quinas pretas que o
    // icon.png (transparente) produziria.
    file: "public/apple-touch-icon.png",
    svg: seal({ bleed: true }),
    px: 180,
    note: "sangrado e opaco — o iOS arredonda com a máscara dele",
  },
];

const browser = await chromium.launch();
for (const t of targets) {
  const out = join(ROOT, t.file);
  if (!t.px) {
    writeFileSync(out, t.svg);
  } else {
    const page = await browser.newPage({
      viewport: { width: t.px, height: t.px },
    });
    await page.setContent(
      `<html><body style="margin:0;background:transparent">${t.svg.replace(
        /width="\d+" height="\d+"/,
        `width="${t.px}" height="${t.px}"`,
      )}</body></html>`,
    );
    writeFileSync(out, await page.screenshot({ omitBackground: true }));
    await page.close();
  }
  console.log(`${t.file.padEnd(28)} ${t.note}`);
}
await browser.close();
