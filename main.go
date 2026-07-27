package main

import (
	gotenbergcmd "github.com/gotenberg/gotenberg/v8/cmd"

	_ "github.com/gotenberg/gotenberg/v8/pkg/standard"
)

func main() {
	gotenbergcmd.Run()
}
