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

# 0. Sincroniza o repo do site antes de publicar (evita push rejeitado quando
#    o origin está à frente; o script pode ser chamado de qualquer diretório).
if [ "$SEM_PUSH" -eq 0 ]; then
  git -C "$RAIZ" pull --rebase --autostash --quiet origin main
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
    -c "../.staticrypt.json" \
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
  SLUG="$(node -e '
    const t = process.argv[1];
    console.log(
      t.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase()
        .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
    );
  ' "$TITULO")"
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
