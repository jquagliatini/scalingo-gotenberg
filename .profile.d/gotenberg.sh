# Gotenberg cherche le binaire Chromium via la variable d'env CHROMIUM_BIN_PATH
# (voir pkg/modules/chromium/chromium.go). Il n'y a pas de flag CLI équivalent.
# Le paquet google-chrome-stable installé par le buildpack APT le pose ici :

export CHROMIUM_BIN_PATH="/app/.apt/opt/google/chrome/google-chrome"
