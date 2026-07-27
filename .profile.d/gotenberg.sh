# Gotenberg cherche le binaire Chromium via la variable d'env CHROMIUM_BIN_PATH
# (voir pkg/modules/chromium/chromium.go). Il n'y a pas de flag CLI équivalent.
# Le paquet google-chrome-stable installé par le buildpack APT le pose ici :

export CHROMIUM_BIN_PATH="/app/.apt/opt/google/chrome/google-chrome"

# Dossier des données d'hyphénation Chromium, téléchargé au build par
# bin/go-post-compile depuis le repo gotenberg upstream. Chromium cherche
# ensuite `<dir>/<chromium-version>/hyph-<lang>.hyb`.

export CHROMIUM_HYPHEN_DATA_DIR_PATH="/app/chromium-hyphen-data"
