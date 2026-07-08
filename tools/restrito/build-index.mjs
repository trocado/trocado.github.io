#!/usr/bin/env node
// Gera _restrito-src/index.html (em claro) a partir de restrito/manifest.json.
// O arquivo gerado é criptografado por tools/restrito/publicar.sh antes de ir ao git.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const raiz = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const manifest = JSON.parse(readFileSync(join(raiz, "restrito", "manifest.json"), "utf8"));

const itens = manifest.relatorios
  .slice()
  .sort((a, b) => b.data.localeCompare(a.data))
  .map(
    (r) =>
      `        <li><span class="data">${r.data}</span> <a href="${r.arquivo}">${r.titulo}</a></li>`
  )
  .join("\n");

const corpo = manifest.relatorios.length
  ? `<ul class="lista">\n${itens}\n      </ul>`
  : `<p class="vazio">Nenhum relatório publicado ainda.</p>`;

const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="robots" content="noindex, nofollow" />
  <title>Relatórios | trocado.com.br</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet" />
  <style>
    :root { --bg: #FAFAF7; --fg: #0A0A0A; --fg-muted: #5C5C5A; --line: #E5E5E1; --green: #10B981; }
    * { box-sizing: border-box; }
    body { margin: 0; background: var(--bg); color: var(--fg); font-family: 'Inter', -apple-system, sans-serif; }
    main { max-width: 640px; margin: 0 auto; padding: 64px 24px; }
    h1 { font-size: 1.5rem; font-weight: 600; margin: 0 0 4px; }
    .sub { color: var(--fg-muted); font-size: 0.9rem; margin: 0 0 32px; font-family: 'JetBrains Mono', monospace; }
    .lista { list-style: none; padding: 0; margin: 0; }
    .lista li { padding: 14px 0; border-bottom: 1px solid var(--line); }
    .data { font-family: 'JetBrains Mono', monospace; font-size: 0.8rem; color: var(--fg-muted); margin-right: 12px; }
    a { color: var(--fg); text-decoration: none; border-bottom: 1px solid var(--green); }
    a:hover { color: var(--green); }
    .vazio { color: var(--fg-muted); }
    footer { margin-top: 48px; font-size: 0.8rem; color: var(--fg-muted); }
    footer a { border-bottom-color: var(--line); }
  </style>
</head>
<body>
  <main>
    <h1>Relatórios</h1>
    <p class="sub">área restrita · trocado.com.br</p>
    ${corpo}
    <footer><a href="/">voltar ao site</a></footer>
  </main>
</body>
</html>
`;

mkdirSync(join(raiz, "_restrito-src"), { recursive: true });
writeFileSync(join(raiz, "_restrito-src", "index.html"), html);
console.log(`Índice gerado em _restrito-src/index.html com ${manifest.relatorios.length} relatório(s).`);
