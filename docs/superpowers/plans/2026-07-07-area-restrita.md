# Área Restrita /restrito Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Área restrita em https://trocado.com.br/restrito/ com relatórios HTML criptografados client-side (AES-256 via StatiCrypt) e skill `/publica-relatorio` para publicação em um comando.

**Architecture:** O repositório `trocado/trocado.github.io` é público e o GitHub Pages é estático, então a criptografia acontece na máquina local antes do commit. Fontes em claro ficam em `_restrito-src/` (gitignored); só o blob criptografado entra em `restrito/`. Um script bash (`tools/restrito/publicar.sh`) faz o pipeline completo (senha do Keychain, criptografia, manifest, índice, commit, push, verificação); a skill em `~/.claude/skills/publica-relatorio/` orquestra o script.

**Tech Stack:** StatiCrypt 3.x via `npx -y staticrypt@3` (Node v22 já instalado), bash, macOS Keychain (`security`), GitHub Actions (workflow `deploy-pages.yml` já existente).

## Global Constraints

- Repositório é PÚBLICO: NUNCA commitar HTML de relatório em claro. `_restrito-src/` deve estar no `.gitignore` antes de qualquer fonte ser criada lá.
- Zero travessão em dash (`—`) em qualquer artefato escrito (spec, skill, HTML, mensagens de commit).
- Commits sem trailer `Co-Authored-By` e sem menção a IA.
- Paleta do site no ar (usar exatamente): fundo `#FAFAF7`, texto `#0A0A0A`, muted `#5C5C5A`, linha `#E5E5E1`, verde `#10B981`, fontes `Inter` + `JetBrains Mono` via Google Fonts. A spec original citava dark/lime; a intenção registrada é "coerente com a identidade do site", e o site é light/emerald. Task 1 corrige a spec.
- Textos de interface em PT-BR.
- Salt compartilhado em `.staticrypt.json` (commitável). Senha no Keychain, serviço `trocado-restrito`, nunca em arquivo.
- Manifest schema fixo: `{"relatorios": [{"arquivo": "AAAA-MM-DD-slug.html", "data": "AAAA-MM-DD", "titulo": "..."}]}`.

---

### Task 1: Fundação (gitignore, robots.txt, template de senha, salt, correção da spec)

**Files:**
- Modify: `.gitignore`
- Create: `robots.txt`
- Create: `tools/restrito/password_template.html`
- Create: `.staticrypt.json` (gerado)
- Modify: `docs/superpowers/specs/2026-07-07-area-restrita-design.md` (seção "Tela de senha e índice")

**Interfaces:**
- Produces: template com todos os placeholders `/*[|...|]*/` do StatiCrypt intactos; `.staticrypt.json` com salt hex de 32 chars usado por TODAS as criptografias futuras.

- [ ] **Step 1: Adicionar `_restrito-src/` ao .gitignore**

Conteúdo final do `.gitignore`:

```
.DS_Store
.claude/
_restrito-src/
```

- [ ] **Step 2: Criar robots.txt**

```
User-agent: *
Allow: /
Disallow: /restrito/
```

- [ ] **Step 3: Criar o template de senha customizado**

Copiar o template padrão do pacote e customizar:

```bash
mkdir -p tools/restrito
TPL=$(find ~/.npm/_npx -path '*staticrypt*' -name password_template.html 2>/dev/null | head -1)
[ -z "$TPL" ] && npx -y staticrypt@3 --version >/dev/null 2>&1 && TPL=$(find ~/.npm/_npx -path '*staticrypt*' -name password_template.html 2>/dev/null | head -1)
cp "$TPL" tools/restrito/password_template.html
```

Em seguida editar `tools/restrito/password_template.html` com EXATAMENTE estas mudanças (preservar intactos todos os placeholders `/*[|...|]*/0`, o bloco `<script>` inteiro, os SVGs base64 e a estrutura de ids/classes):

1. Trocar `<html class="staticrypt-html">` por `<html lang="pt-BR" class="staticrypt-html">`.
2. Logo após `<meta name="viewport" ...>`, inserir:

```html
        <meta name="robots" content="noindex, nofollow" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        <link
            href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap"
            rel="stylesheet"
        />
```

3. Substituir o bloco `<style>...</style>` inteiro por:

```html
        <style>
            .staticrypt-hr {
                margin: 20px 0;
                border: 0;
                border-top: 1px solid #e5e5e1;
            }

            .staticrypt-page {
                width: 360px;
                padding: 8% 0 0;
                margin: auto;
                box-sizing: border-box;
            }

            .staticrypt-form {
                position: relative;
                z-index: 1;
                background: #ffffff;
                border: 1px solid #e5e5e1;
                border-radius: 8px;
                max-width: 360px;
                margin: 0 auto 100px;
                padding: 45px;
                text-align: center;
            }

            .staticrypt-form input[type="password"],
            input[type="text"] {
                background: inherit;
                border: 0;
                box-sizing: border-box;
                font-family: "JetBrains Mono", monospace;
                font-size: 14px;
                color: #0a0a0a;
                outline: 0;
                padding: 15px 30px 15px 15px;
                width: 100%;
            }

            .staticrypt-password-container {
                position: relative;
                outline: 0;
                background: #fafaf7;
                border: 1px solid #e5e5e1;
                border-radius: 6px;
                width: 100%;
                margin: 0 0 15px;
                box-sizing: border-box;
            }

            .staticrypt-toggle-password-visibility {
                cursor: pointer;
                height: 20px;
                opacity: 60%;
                padding: 13px;
                position: absolute;
                right: 0;
                top: 50%;
                transform: translateY(-50%);
                width: 20px;
            }

            .staticrypt-form .staticrypt-decrypt-button {
                text-transform: uppercase;
                letter-spacing: 0.08em;
                outline: 0;
                background: /*[|template_color_primary|]*/ 0;
                width: 100%;
                border: 0;
                border-radius: 6px;
                padding: 15px;
                color: #ffffff;
                font-family: "Inter", sans-serif;
                font-weight: 600;
                font-size: 14px;
                cursor: pointer;
            }

            .staticrypt-form .staticrypt-decrypt-button:hover,
            .staticrypt-form .staticrypt-decrypt-button:active,
            .staticrypt-form .staticrypt-decrypt-button:focus {
                background: /*[|template_color_primary|]*/ 0;
                filter: brightness(92%);
            }

            .staticrypt-html {
                height: 100%;
            }

            .staticrypt-body {
                height: 100%;
                margin: 0;
            }

            .staticrypt-content {
                height: 100%;
                margin-bottom: 1em;
                background: /*[|template_color_secondary|]*/ 0;
                font-family: "Inter", -apple-system, BlinkMacSystemFont, sans-serif;
                color: #0a0a0a;
                -webkit-font-smoothing: antialiased;
                -moz-osx-font-smoothing: grayscale;
            }

            .staticrypt-instructions {
                margin-top: -1em;
                margin-bottom: 1em;
            }

            .staticrypt-instructions > p:not(.staticrypt-title) {
                color: #5c5c5a;
                font-size: 14px;
            }

            .staticrypt-title {
                font-size: 1.35em;
                font-weight: 600;
            }

            label.staticrypt-remember {
                display: flex;
                align-items: center;
                margin-bottom: 1em;
                color: #5c5c5a;
                font-size: 13px;
                text-align: left;
            }

            .staticrypt-remember input[type="checkbox"] {
                transform: scale(1.3);
                margin-right: 1em;
                accent-color: #10b981;
            }

            .hidden {
                display: none !important;
            }

            .staticrypt-spinner-container {
                height: 100%;
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .staticrypt-spinner {
                display: inline-block;
                width: 2rem;
                height: 2rem;
                vertical-align: text-bottom;
                border: 0.25em solid #10b981;
                border-right-color: transparent;
                border-radius: 50%;
                animation: spinner-border 0.75s linear infinite;
            }

            @keyframes spinner-border {
                100% {
                    transform: rotate(360deg);
                }
            }

            @media screen and (-webkit-min-device-pixel-ratio: 0) {
                .staticrypt-form input[type="password"],
                input[type="text"] {
                    font-size: 16px;
                }
            }
        </style>
```

- [ ] **Step 4: Gerar o salt compartilhado**

```bash
npx -y staticrypt@3 --salt
```

Expected: imprime um salt hexadecimal de 32 chars e cria `.staticrypt.json` na raiz. Se o comando exigir um filename e falhar, fallback:

```bash
echo "{\"salt\": \"$(openssl rand -hex 16)\"}" > .staticrypt.json
```

Verificar: `cat .staticrypt.json` mostra `{"salt": "<32 chars hex>"}`.

- [ ] **Step 5: Corrigir a seção visual da spec**

Em `docs/superpowers/specs/2026-07-07-area-restrita-design.md`, substituir a linha:

```
- Template do StatiCrypt customizado: PT-BR, fundo dark, tipografia Space Grotesk, acentos lime/cyan, coerente com a identidade VECTOR do site.
```

por:

```
- Template do StatiCrypt customizado: PT-BR, paleta do site no ar (fundo #FAFAF7, verde #10B981, Inter + JetBrains Mono). Ajustado em relação ao rascunho original (dark/lime) porque o requisito dominante é coerência com o site publicado, que é light/emerald.
```

- [ ] **Step 6: Verificar que o template preservou os placeholders**

```bash
grep -c '.\*\[|' tools/restrito/password_template.html || grep -o '/\*\[|[a-z_]*|\]\*/' tools/restrito/password_template.html | sort -u
```

Expected: aparecem `template_title`, `template_instructions`, `template_placeholder`, `template_remember`, `template_button`, `template_error`, `template_toggle_show`, `template_toggle_hide`, `template_color_primary`, `template_color_secondary`, `js_staticrypt`, `is_remember_enabled`, `staticrypt_config`.

- [ ] **Step 7: Commit**

```bash
git add .gitignore robots.txt tools/restrito/password_template.html .staticrypt.json docs/superpowers/specs/2026-07-07-area-restrita-design.md
git commit -m "Prepara fundação da área restrita: template de senha, salt e robots.txt"
```

---

### Task 2: Manifest e gerador de índice

**Files:**
- Create: `restrito/manifest.json`
- Create: `tools/restrito/build-index.mjs`

**Interfaces:**
- Consumes: nada de tasks anteriores (independente do template).
- Produces: `node tools/restrito/build-index.mjs` lê `restrito/manifest.json` e escreve `_restrito-src/index.html` em claro. Schema do manifest: `{"relatorios": [{"arquivo", "data", "titulo"}]}`.

- [ ] **Step 1: Criar manifest vazio**

`restrito/manifest.json`:

```json
{
  "relatorios": []
}
```

- [ ] **Step 2: Criar o gerador de índice**

`tools/restrito/build-index.mjs`:

```javascript
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
```

- [ ] **Step 3: Testar com manifest vazio**

```bash
node tools/restrito/build-index.mjs && grep -c "Nenhum relatório publicado ainda" _restrito-src/index.html
```

Expected: `Índice gerado ... 0 relatório(s).` e grep retorna `1`.

- [ ] **Step 4: Testar com manifest populado (fixture temporária)**

```bash
cp restrito/manifest.json .manifest.bak
cat > restrito/manifest.json <<'EOF'
{
  "relatorios": [
    { "arquivo": "2026-01-01-a.html", "data": "2026-01-01", "titulo": "A" },
    { "arquivo": "2026-06-15-b.html", "data": "2026-06-15", "titulo": "B" }
  ]
}
EOF
node tools/restrito/build-index.mjs
grep -o 'href="2026-[^"]*"' _restrito-src/index.html
mv .manifest.bak restrito/manifest.json
node tools/restrito/build-index.mjs
```

Expected: os dois hrefs aparecem, com `2026-06-15-b.html` listado ANTES de `2026-01-01-a.html` (ordem decrescente por data). Manifest restaurado ao final.

- [ ] **Step 5: Commit**

```bash
git add restrito/manifest.json tools/restrito/build-index.mjs
git commit -m "Adiciona manifest e gerador de índice da área restrita"
```

---

### Task 3: Script publicar.sh e índice inicial criptografado

**Files:**
- Create: `tools/restrito/publicar.sh`
- Create: `restrito/index.html` (criptografado, gerado pelo script)

**Interfaces:**
- Consumes: `tools/restrito/password_template.html` e `.staticrypt.json` (Task 1); `tools/restrito/build-index.mjs` e schema do manifest (Task 2).
- Produces: `./tools/restrito/publicar.sh <arquivo.html> [--titulo "..."] [--sem-push]` e `./tools/restrito/publicar.sh --so-indice [--sem-push]`. Senha no Keychain serviço `trocado-restrito`, conta `$USER`.

- [ ] **Step 1: Criar o script**

`tools/restrito/publicar.sh`:

```bash
#!/usr/bin/env bash
# Publica um relatório HTML na área restrita de trocado.com.br.
# Uso:
#   tools/restrito/publicar.sh <arquivo.html> [--titulo "Título"] [--sem-push]
#   tools/restrito/publicar.sh --so-indice [--sem-push]
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
SERVICO_KEYCHAIN="trocado-restrito"
URL_BASE="https://trocado.com.br/restrito"

ARQUIVO=""
TITULO=""
SEM_PUSH=0
SO_INDICE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --titulo) TITULO="$2"; shift 2 ;;
    --sem-push) SEM_PUSH=1; shift ;;
    --so-indice) SO_INDICE=1; shift ;;
    *) ARQUIVO="$1"; shift ;;
  esac
done

if [ "$SO_INDICE" -eq 0 ] && [ -z "$ARQUIVO" ]; then
  echo "Uso: $0 <arquivo.html> [--titulo \"Título\"] [--sem-push] | --so-indice" >&2
  exit 1
fi

# 1. Senha-mestre: lê do Keychain; cria se não existir.
SENHA="$(security find-generic-password -s "$SERVICO_KEYCHAIN" -w 2>/dev/null || true)"
if [ -z "$SENHA" ]; then
  SENHA="$(node -e '
    const fs = require("fs");
    const palavras = fs.readFileSync("/usr/share/dict/words", "utf8")
      .split("\n").filter((p) => /^[a-z]{4,8}$/.test(p));
    const sorteia = () => palavras[Math.floor(Math.random() * palavras.length)];
    console.log([sorteia(), sorteia(), sorteia(), sorteia()].join("-"));
  ')"
  security add-generic-password -a "$USER" -s "$SERVICO_KEYCHAIN" -w "$SENHA"
  echo "ATENÇÃO: senha-mestre criada e guardada no Keychain (serviço $SERVICO_KEYCHAIN):"
  echo "  $SENHA"
  echo "Anote em local seguro. Sem ela os relatórios são ilegíveis."
fi

# Criptografa um arquivo de _restrito-src/ para restrito/ com o template do site.
criptografar() {
  local nome="$1" titulo_pagina="$2"
  (cd "$RAIZ/_restrito-src" && STATICRYPT_PASSWORD="$SENHA" npx -y staticrypt@3 "$nome" \
    -c "$RAIZ/.staticrypt.json" \
    -d "$RAIZ/restrito" \
    --remember 30 \
    --short \
    -t "$RAIZ/tools/restrito/password_template.html" \
    --template-title "$titulo_pagina" \
    --template-instructions "Área restrita de trocado.com.br. Digite a senha para continuar." \
    --template-button "Entrar" \
    --template-placeholder "Senha" \
    --template-remember "Lembrar neste navegador por 30 dias" \
    --template-error "Senha incorreta." \
    --template-toggle-show "Mostrar senha" \
    --template-toggle-hide "Ocultar senha" \
    --template-color-primary "#10B981" \
    --template-color-secondary "#FAFAF7")
}

mkdir -p "$RAIZ/_restrito-src"
MSG_COMMIT="Atualiza índice da área restrita"

if [ "$SO_INDICE" -eq 0 ]; then
  # 2. Valida entrada e monta nome do arquivo publicado.
  if [ ! -f "$ARQUIVO" ]; then
    echo "Arquivo não encontrado: $ARQUIVO" >&2
    exit 1
  fi
  if [ -z "$TITULO" ]; then
    TITULO="$(basename "$ARQUIVO" .html)"
  fi
  DATA="$(date +%Y-%m-%d)"
  SLUG="$(printf '%s' "$TITULO" | iconv -f utf-8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
  NOME_PUB="$DATA-$SLUG.html"

  # 3. Copia a fonte em claro para a área gitignored e criptografa.
  cp "$ARQUIVO" "$RAIZ/_restrito-src/$NOME_PUB"
  criptografar "$NOME_PUB" "$TITULO"
  echo "Criptografado: restrito/$NOME_PUB"

  # 4. Atualiza o manifest (substitui entrada de mesmo arquivo, se houver).
  node -e '
    const fs = require("fs");
    const [arq, nome, data, titulo] = process.argv.slice(1);
    const m = JSON.parse(fs.readFileSync(arq, "utf8"));
    m.relatorios = m.relatorios.filter((r) => r.arquivo !== nome);
    m.relatorios.push({ arquivo: nome, data, titulo });
    fs.writeFileSync(arq, JSON.stringify(m, null, 2) + "\n");
  ' "$RAIZ/restrito/manifest.json" "$NOME_PUB" "$DATA" "$TITULO"
  MSG_COMMIT="Publica relatório na área restrita: $TITULO"
fi

# 5. Regenera e recriptografa o índice.
node "$RAIZ/tools/restrito/build-index.mjs"
criptografar "index.html" "Relatórios"

# 6. Commit.
cd "$RAIZ"
git add restrito
git commit -m "$MSG_COMMIT"

if [ "$SEM_PUSH" -eq 1 ]; then
  echo "Commit feito sem push (--sem-push). Nada foi publicado."
  exit 0
fi

# 7. Push e verificação: a URL deve responder com a tela de senha, nunca com conteúdo em claro.
git push origin main
ALVO="$URL_BASE/"
[ "$SO_INDICE" -eq 0 ] && ALVO="$URL_BASE/$NOME_PUB"
echo "Aguardando deploy do GitHub Pages para verificar $ALVO ..."
for i in $(seq 1 30); do
  CORPO="$(curl -fsS "$ALVO" 2>/dev/null || true)"
  if printf '%s' "$CORPO" | grep -q "staticrypt"; then
    echo "OK: página no ar exigindo senha."
    exit 0
  fi
  sleep 10
done
echo "AVISO: não confirmei o deploy em 5 minutos. Verifique manualmente: $ALVO" >&2
exit 1
```

- [ ] **Step 2: Dar permissão de execução**

```bash
chmod +x tools/restrito/publicar.sh
```

- [ ] **Step 3: Testar ponta a ponta local com fixture (sem push)**

```bash
cat > "$TMPDIR/relatorio-fixture.html" <<'EOF'
<!DOCTYPE html><html lang="pt-BR"><head><meta charset="utf-8"><title>Fixture</title></head>
<body><h1>MARCADOR_SECRETO_XYZ123</h1></body></html>
EOF
./tools/restrito/publicar.sh "$TMPDIR/relatorio-fixture.html" --titulo "Relatório Fixture" --sem-push
```

Expected: senha criada no Keychain (primeira execução, anotar a passphrase exibida), arquivo `restrito/$(date +%Y-%m-%d)-relatorio-fixture.html` criado, manifest atualizado, índice recriptografado, commit local feito, mensagem "sem push".

- [ ] **Step 4: Verificar que o ciphertext não vaza o conteúdo**

```bash
grep -c "MARCADOR_SECRETO_XYZ123" restrito/$(date +%Y-%m-%d)-relatorio-fixture.html || echo "SEM VAZAMENTO"
grep -q "staticrypt" restrito/index.html && echo "INDICE CRIPTOGRAFADO"
```

Expected: `SEM VAZAMENTO` e `INDICE CRIPTOGRAFADO`.

- [ ] **Step 5: Verificar roundtrip de descriptografia**

```bash
SENHA="$(security find-generic-password -s trocado-restrito -w)"
mkdir -p "$TMPDIR/decrypt-check"
(cd restrito && STATICRYPT_PASSWORD="$SENHA" npx -y staticrypt@3 "$(date +%Y-%m-%d)-relatorio-fixture.html" --decrypt -c ../.staticrypt.json -d "$TMPDIR/decrypt-check")
grep -c "MARCADOR_SECRETO_XYZ123" "$TMPDIR/decrypt-check/$(date +%Y-%m-%d)-relatorio-fixture.html"
```

Expected: `1` (conteúdo recuperado com a senha correta).

- [ ] **Step 6: Desfazer o commit da fixture**

```bash
git reset --hard HEAD~1
git log --oneline -1
ls restrito/
```

Expected: HEAD volta ao commit da Task 2 (fixture removida de `restrito/`), sobrando apenas `manifest.json` em `restrito/`.

- [ ] **Step 7: Gerar o índice inicial real (criptografado, sem push ainda)**

```bash
./tools/restrito/publicar.sh --so-indice --sem-push
git add tools/restrito/publicar.sh
git commit --amend --no-edit
```

Expected: `restrito/index.html` criptografado commitado junto com o script, em um commit "Atualiza índice da área restrita".

---

### Task 4: Deploy (workflow + go-live da área)

**Files:**
- Modify: `.github/workflows/deploy-pages.yml` (step "Prepara conteudo publicavel")

**Interfaces:**
- Consumes: `restrito/` com `index.html` e `manifest.json` commitados (Task 3), `robots.txt` (Task 1).

- [ ] **Step 1: Incluir restrito/ e robots.txt no artefato de deploy**

No step `Prepara conteudo publicavel (sem rascunhos)`, trocar o bloco `run` por:

```yaml
        run: |
          mkdir -p _site
          cp index.html pessoal.html robots.txt _site/
          cp -r assets brand restrito _site/
          touch _site/.nojekyll
          echo "trocado.com.br" > _site/CNAME
```

- [ ] **Step 2: Commit e push**

```bash
git add .github/workflows/deploy-pages.yml
git commit -m "Publica área restrita /restrito e robots.txt no deploy"
git push origin main
```

- [ ] **Step 3: Verificar o deploy no ar**

```bash
gh run watch --exit-status $(gh run list --workflow deploy-pages.yml --limit 1 --json databaseId -q '.[0].databaseId')
curl -fsS https://trocado.com.br/restrito/ | grep -q staticrypt && echo "AREA NO AR COM SENHA"
curl -fsS https://trocado.com.br/robots.txt | grep -q "Disallow: /restrito/" && echo "ROBOTS OK"
```

Expected: workflow verde, `AREA NO AR COM SENHA`, `ROBOTS OK`.

---

### Task 5: Skill /publica-relatorio

**Files:**
- Create: `~/.claude/skills/publica-relatorio/SKILL.md`

**Interfaces:**
- Consumes: `tools/restrito/publicar.sh` (Task 3) com a assinatura `publicar.sh <arquivo.html> [--titulo "..."] [--sem-push]`.

- [ ] **Step 1: Criar a skill**

`~/.claude/skills/publica-relatorio/SKILL.md`:

```markdown
---
name: publica-relatorio
description: Publica um relatório HTML na área restrita de trocado.com.br (https://trocado.com.br/restrito/), protegida por senha com criptografia client-side. Use SEMPRE que o Leandro disser "/publica-relatorio", "publica esse relatório", "sobe pra área restrita", "guarda na área restrita", "manda pro restrito", ou pedir para arquivar um relatório HTML para consulta posterior no site pessoal. NÃO use para conteúdo de sensibilidade média ou alta (dados do Serpros, pessoas, fornecedores, valores contratuais): a área aceita apenas conteúdo pessoal de baixa sensibilidade.
---

# Publica relatório na área restrita

## O que esta skill faz

Criptografa um HTML autocontido com AES-256 (StatiCrypt), publica em
https://trocado.com.br/restrito/, atualiza o índice e verifica o deploy.
O repositório é público: a fonte em claro NUNCA entra no git.

## Pré-requisitos

- Repo local: `/Users/trocado/dev/trocado.com.br`
- Senha-mestre no Keychain do macOS, serviço `trocado-restrito` (o script cria na primeira execução e exibe a passphrase; nesse caso, repasse a passphrase ao Leandro com destaque)

## Workflow

1. Identifique o arquivo HTML a publicar. Se o relatório ainda não existe como arquivo, salve-o primeiro (autocontido: CSS/JS inline, sem dependências locais).
2. Confira o guardrail de sensibilidade: se o conteúdo citar Serpros, pessoas da equipe, fornecedores ou valores contratuais, PARE e avise o Leandro que essa área é só para conteúdo pessoal de baixa sensibilidade.
3. Defina um título neutro (os nomes de arquivo são públicos no repo; o conteúdo não). Errado: "Análise salarial GETEC". Certo: "Relatório mensal 07".
4. Execute:

   cd /Users/trocado/dev/trocado.com.br && ./tools/restrito/publicar.sh <caminho-do-html> --titulo "<Título Neutro>"

5. O script criptografa, atualiza `restrito/manifest.json`, regenera o índice, commita, pusha e espera o deploy (até 5 min), confirmando que a URL responde com a tela de senha.
6. Responda ao Leandro com a URL final (https://trocado.com.br/restrito/AAAA-MM-DD-slug.html) e a URL do índice.

## Manutenção

- Regenerar só o índice (ex.: após editar manifest na mão): `./tools/restrito/publicar.sh --so-indice`
- Trocar a senha: apagar a entrada do Keychain (`security delete-generic-password -s trocado-restrito`), rodar `--so-indice` para criar senha nova e republicar CADA relatório a partir da fonte em `_restrito-src/`. Arquivos antigos no histórico do git continuam protegidos pela senha antiga.
```

- [ ] **Step 2: Verificar estrutura da skill**

```bash
head -5 ~/.claude/skills/publica-relatorio/SKILL.md
```

Expected: frontmatter com `name: publica-relatorio` na segunda linha.

---

### Task 6: Publicação real ponta a ponta e critérios de sucesso

**Files:**
- Create: `_restrito-src/` fonte do primeiro relatório real (gitignored)
- Create: `restrito/<data>-guia-da-area-restrita.html` (via script)

**Interfaces:**
- Consumes: pipeline completo das Tasks 1 a 5.

- [ ] **Step 1: Criar o primeiro relatório real (guia de uso da própria área)**

Salvar em `$TMPDIR/guia-area-restrita.html`:

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Guia da área restrita</title>
  <style>
    :root { --bg: #FAFAF7; --fg: #0A0A0A; --muted: #5C5C5A; --line: #E5E5E1; --green: #10B981; }
    body { margin: 0; background: var(--bg); color: var(--fg); font-family: 'Inter', -apple-system, sans-serif; }
    main { max-width: 640px; margin: 0 auto; padding: 64px 24px; line-height: 1.6; }
    h1 { font-size: 1.5rem; } h2 { font-size: 1.1rem; margin-top: 2em; }
    code { background: #fff; border: 1px solid var(--line); border-radius: 4px; padding: 1px 6px; font-size: 0.85em; }
    a { color: var(--green); }
  </style>
</head>
<body>
<main>
  <h1>Guia da área restrita</h1>
  <p>Este é o primeiro relatório publicado na área restrita de trocado.com.br. Serve de referência de uso.</p>
  <h2>Como publicar um relatório novo</h2>
  <p>No Claude Code, diga <code>publica esse relatório</code> apontando para um HTML autocontido, ou rode direto: <code>./tools/restrito/publicar.sh arquivo.html --titulo "Título Neutro"</code>.</p>
  <h2>Regras</h2>
  <p>Somente conteúdo pessoal de baixa sensibilidade. Títulos neutros: os nomes de arquivo são públicos no repositório, o conteúdo não. A senha fica no Keychain do macOS (serviço <code>trocado-restrito</code>).</p>
  <h2>Acesso</h2>
  <p>Índice em <a href="/restrito/">trocado.com.br/restrito/</a>. Marque "Lembrar neste navegador" para não redigitar a senha por 30 dias.</p>
</main>
</body>
</html>
```

- [ ] **Step 2: Publicar via script (fluxo completo, com push)**

```bash
./tools/restrito/publicar.sh "$TMPDIR/guia-area-restrita.html" --titulo "Guia da área restrita"
```

Expected: termina com `OK: página no ar exigindo senha.`

- [ ] **Step 3: Rodar os 5 critérios de sucesso da spec**

```bash
# 1. Área no ar exigindo senha
curl -fsS https://trocado.com.br/restrito/ | grep -q staticrypt && echo "CRITERIO 1 OK"
# 2. Relatório no ar exigindo senha e sem conteúdo em claro
URL="https://trocado.com.br/restrito/$(date +%Y-%m-%d)-guia-da-area-restrita.html"
CORPO=$(curl -fsS "$URL")
echo "$CORPO" | grep -q staticrypt && ! echo "$CORPO" | grep -q "primeiro relatório publicado" && echo "CRITERIO 2 OK"
# 3. Nenhum HTML de relatório em claro no histórico
git log --all --diff-filter=A --name-only --pretty=format: | sort -u | grep "^_restrito-src" && echo "CRITERIO 3 FALHOU" || echo "CRITERIO 3 OK"
# 4. Relatório aparece no índice (verificação local: descriptografa o índice)
SENHA="$(security find-generic-password -s trocado-restrito -w)"
mkdir -p "$TMPDIR/check-indice"
(cd restrito && STATICRYPT_PASSWORD="$SENHA" npx -y staticrypt@3 index.html --decrypt -c ../.staticrypt.json -d "$TMPDIR/check-indice")
grep -q "guia-da-area-restrita" "$TMPDIR/check-indice/index.html" && echo "CRITERIO 4 OK"
# 5. Remember cross-page: garantido por salt compartilhado; verificar que só existe 1 salt
cat .staticrypt.json && echo "CRITERIO 5 OK (salt único em .staticrypt.json)"
```

Expected: os 5 `CRITERIO N OK`.

O critério 5 (senha lembrada entre páginas) tem verificação estrutural aqui (salt único); a confirmação final é manual pelo Leandro no navegador.

- [ ] **Step 4: Reportar ao Leandro**

Entregar: URL do índice, URL do guia, a passphrase gerada (se foi criada nesta sessão), onde ela está guardada, e o lembrete de testar "Lembrar neste navegador" no celular e no desktop.
