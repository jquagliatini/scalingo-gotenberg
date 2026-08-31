# scalingo-gotenberg

[![Deploy on Scalingo](https://cdn.scalingo.com/deploy/button.svg)](https://dashboard.scalingo.com/create/app?source=https://github.com/jquagliatini/scalingo-gotenberg)

Déploiement de [Gotenberg](https://gotenberg.dev/) sur Scalingo derrière un
reverse proxy nginx, sans LibreOffice (route désactivée).

## Architecture

Un dyno Scalingo `scalingo-24` avec :

- **APT buildpack** — installe Google Chrome, qpdf, exiftool, fonts…
- **Go buildpack** — compile Gotenberg v8.34.0 depuis les sources
- **nginx buildpack** — reverse proxy `$PORT` → `127.0.0.1:3000`
- **supervisord** (PID 1) — orchestre `nginx` + `gotenberg`

Le binaire pdfcpu est téléchargé par `bin/go-post-compile` (hook du Go
buildpack). Pas de pdftk — les moteurs `qpdf` + `pdfcpu` couvrent tous les
usages configurés dans `supervisord.conf`.

## Déploiement

```bash
scalingo create scalingo-gotenberg --stack scalingo-24
scalingo -a scalingo-gotenberg scale web:1:L
git push scalingo main
```

Le fichier `.buildpacks` déclenche automatiquement le mode multi-buildpack
(pas besoin de `BUILDPACK_URL`).

## Vérification

```bash
# 1. Logs de démarrage
scalingo -a scalingo-gotenberg logs -n 200

# 2. Health check
curl https://scalingo-gotenberg.osc-fr1.scalingo.io/health

# 3. Conversion Chromium
curl -X POST https://scalingo-gotenberg.osc-fr1.scalingo.io/forms/chromium/convert/url \
  -F url=https://example.com -o out.pdf
file out.pdf

# 4. Inspection en session bash
scalingo -a scalingo-gotenberg run bash
> which qpdf exiftool pdfcpu
> ls -la /app/.apt/opt/google/chrome/
> /app/bin/scalingo-gotenberg --help | head -50
```

## Fichiers clés

| Fichier              | Rôle                                              |
| -------------------- | ------------------------------------------------- |
| `.buildpacks`        | ordre des buildpacks (APT → Go → nginx)           |
| `Aptfile`            | paquets système + dépôt Google Chrome             |
| `go.mod`, `main.go`  | wrapper minimal du binaire Gotenberg              |
| `bin/go-pre-compile` | génère `go.sum` s'il est absent                   |
| `bin/go-post-compile`| télécharge le binaire pdfcpu                      |
| `bin/start-gotenberg`| lance gotenberg, attend /health, tient la main    |
| `servers.conf.erb`   | server nginx + rate limit + upstream gotenberg    |
| `supervisord.conf`   | orchestration nginx (`bin/run`) + gotenberg       |
| `Procfile`           | `web: supervisord -c supervisord.conf`            |

## Points d'attention

- **Chromium sur Ubuntu 24.04** — le paquet `chromium` d'APT est un stub snap
  inutilisable dans un buildpack. On utilise `google-chrome-stable` via le
  dépôt officiel Google (`dl.google.com`). Le binaire est à
  `/app/.apt/opt/google/chrome/google-chrome`, passé à Gotenberg via
  `--chromium-bin-path`.
- **Version Go** — Gotenberg v8.34.0 requiert Go 1.26.2. Vérifier que le
  buildpack Go Scalingo prend en charge cette version ; sinon, ajouter la
  directive `toolchain` à `go.mod` ou downgrade Gotenberg.
- **Taille du slug** — Chrome + fonts restent gérables (~200 MB). Utiliser
  un dyno `M` ou `L` selon le trafic.
- **Un seul port exposé** — nginx bind `$PORT`, Gotenberg reste sur
  `127.0.0.1:9091` (choix d'un port hors plage `$PORT` typique de Scalingo
  pour éviter toute collision). Vérifier après déploiement.
- **Choix `servers.conf.erb` vs `nginx.conf.erb`** — le nginx-buildpack
  Scalingo inclut `nginx.conf.erb` **à l'intérieur** d'un `server { }` déjà
  déclaré. Or `limit_req_zone` doit être au niveau `http { }`. On utilise
  donc `servers.conf.erb`, inclus au niveau `http`, ce qui nous permet
  aussi de définir un `upstream`.
- **Orchestration nginx** — le buildpack expose `/app/bin/run` qui rend la
  config et lance nginx en foreground. Ce script sort si nginx meurt ;
  supervisord le relance.

## Génération de `go.sum` en local (recommandé)

Le script `bin/go-pre-compile` génère `go.sum` à la volée si absent (en
appelant `go mod tidy` sur le dyno de build). C'est un filet de sécurité :
en pratique, mieux vaut le générer **localement** et le committer pour
avoir un build reproductible :

```bash
cd scalingo-gotenberg
go mod tidy
git add go.sum
```

## Moteurs PDF

`supervisord.conf` configure explicitement chaque opération PDF (l'option
globale `--pdfengines-engines` est dépréciée dans Gotenberg 8) :

- `--pdfengines-merge-engines=qpdf,pdfcpu` — fusion
- `--pdfengines-split-engines=pdfcpu,qpdf` — découpage
- `--pdfengines-encrypt-engines=qpdf,pdfcpu` — chiffrement
- `--pdfengines-watermark-engines=pdfcpu` — filigrane (qpdf ne le fait pas)
- `--pdfengines-rotate-engines=pdfcpu` — rotation (qpdf ne le fait pas)

L'ordre dans chaque liste = ordre de fallback. Aucune route ne fait appel à
pdftk, donc pas besoin de JRE.

## Configuration alternative

Pour activer/désactiver d'autres routes Gotenberg, ajuster la ligne `command`
de `supervisord.conf`. Options utiles :

- `--chromium-disable-routes=true` — désactive complètement Chromium
- `--pdfengines-disable-routes=true` — désactive tous les moteurs PDF
- `--webhook-*` — configuration des webhooks asynchrones
