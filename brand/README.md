# trocado. · Vector Identity

Sistema de marca pessoal — versão 002. Conceito: **VECTOR**. Direção é o novo recurso.

## Visualizar

```bash
open brand-preview.html
```

## Conceito

Mark composto por três elementos:
- **Rastro** (chevron ciano semi-transparente): contexto, memória, repertório acumulado
- **Vetor** (chevron lime sólido): direção atual, decisão presente
- **Alvo** (ponto laser orange): objetivo, próximo movimento

Leitura: trajetória do passado ao próximo passo. Movimento intencional sobre infraestrutura sólida — IA, harness, clear thinking, travel.

## Paleta

| Token | Hex | Função |
|---|---|---|
| Off-black | `#0A0A0A` | Base, fundo principal |
| Acid Lime | `#D4FF00` | Primary, direção, acento principal |
| Electric Cyan | `#06B6D4` | Secondary, rastro, contexto |
| Laser Orange | `#FB923C` | Accent, alvo, ponto |
| Off-white | `#FAFAFA` | Texto sobre fundo escuro |

## Tipografia

- **Display + Body:** Space Grotesk (300/400/500/600/700) — Google Fonts variable
- **Mono:** JetBrains Mono (400/500/700)

Sem serifa. Sem ornamento. Voz técnica + grotesque variable.

## Arquivos

| Arquivo | Uso |
|---|---|
| `logo-primary.svg` | Mark com gradiente lime — sobre fundos claros |
| `logo-reverse.svg` | Mark com ciano mais legível — sobre fundos escuros |
| `logo-mono.svg` | Monocromática (`currentColor`) — herda cor do contexto |
| `wordmark.svg` | Mark + "trocado" em Space Grotesk 700 |
| `wordmark-short.svg` | Versão dark com label "LEANDRO" mono + "trocado." |
| `favicon.svg` | 32×32 com cantos arredondados |
| `avatar-1024.svg` | 1024² com mesh gradient + grid técnico |
| `linkedin-banner.svg` | 1584×396 com mesh + wordmark + tagline + coordenada |
| `email-signature.svg` | Bloco dark com lateral lime — Outlook/Gmail |
| `brand-preview.html` | Brand book completo em dark bento grid |

## Tagline

**Principal:** *Direction is the new asset.*

Alternativas:
- *Pensamento vetorial.* (pt-BR curto)
- *Do sinal à direção.* (pt-BR narrativo)

## Aplicação rápida

1. **LinkedIn** → exportar `linkedin-banner.svg` como PNG 1584×396 + `avatar-1024.svg` como PNG 1024² (use Preview no macOS ou rsvg-convert)
2. **Outlook/Gmail** → exportar `email-signature.svg` como PNG 600px largura, colar no editor HTML da assinatura
3. **Site** `trocado.com.br` → usar `favicon.svg` direto + paleta CSS já no preview
4. **Slides** → criar tema escuro com Off-black + Lime + Space Grotesk
5. **Currículo** → usar `wordmark.svg` no header, paleta como acentos discretos

## Exportar PNG via terminal

```bash
# se tiver rsvg-convert (brew install librsvg)
rsvg-convert -w 1584 linkedin-banner.svg -o linkedin-banner.png
rsvg-convert -w 1024 avatar-1024.svg -o avatar-1024.png
rsvg-convert -w 600 email-signature.svg -o email-signature.png
```

Ou abrir cada SVG no Preview do macOS → Exportar como PNG.
