package main

import (
	gotenbergcmd "github.com/gotenberg/gotenberg/v8/cmd"

	// On n'importe pas `pkg/standard` : il tire libreoffice et pdftk, qui
	// exigent au boot les env vars LIBREOFFICE_BIN_PATH, UNOCONVERTER_BIN_PATH
	// et PDFTK_BIN_PATH pointant vers des binaires réels (checks os.Stat).
	// On liste explicitement uniquement les modules dont on a le binaire.
	_ "github.com/gotenberg/gotenberg/v8/pkg/modules/api"
	_ "github.com/gotenberg/gotenberg/v8/pkg/modules/chromium"
	_ "github.com/gotenberg/gotenberg/v8/pkg/modules/exiftool"
	_ "github.com/gotenberg/gotenberg/v8/pkg/modules/pdfcpu"
	_ "github.com/gotenberg/gotenberg/v8/pkg/modules/pdfengines"
	_ "github.com/gotenberg/gotenberg/v8/pkg/modules/prometheus"
	_ "github.com/gotenberg/gotenberg/v8/pkg/modules/qpdf"
	_ "github.com/gotenberg/gotenberg/v8/pkg/modules/webhook"
)

func main() {
	gotenbergcmd.Run()
}
