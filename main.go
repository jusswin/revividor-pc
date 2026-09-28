// RevividorPC.exe — un clic, en espanol, sin mentiras.
// Revive un PC Windows lento: punto de restauracion, quita bloatware,
// apaga arranque automatico, telemetria y pone modo rapido.
package main

import (
	"bufio"
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

//go:embed revividor.ps1
var script string

func isAdmin() bool {
	// "net session" solo funciona con permiso de administrador.
	return exec.Command("net", "session").Run() == nil
}

func relaunchAsAdmin() {
	exe, err := os.Executable()
	if err != nil {
		fmt.Println("No pude reiniciarme como administrador:", err)
		pause()
		os.Exit(1)
	}
	ps := fmt.Sprintf("Start-Process -FilePath %q -Verb RunAs", exe)
	exec.Command("powershell", "-NoProfile", "-Command", ps).Run()
}

func pause() {
	fmt.Println()
	fmt.Println("Presiona Enter para salir...")
	bufio.NewReader(os.Stdin).ReadString('\n')
}

func main() {
	if !isAdmin() {
		fmt.Println("El Revividor necesita permiso de administrador para limpiar tu PC.")
		fmt.Println("En el aviso de Windows pulsa 'Si' para continuar...")
		relaunchAsAdmin()
		return
	}
	dir := filepath.Join(os.Getenv("TEMP"), "Trollhunters")
	if err := os.MkdirAll(dir, 0755); err != nil {
		fmt.Println("Error preparando carpeta temporal:", err)
		pause()
		return
	}
	ps1 := filepath.Join(dir, "revividor.ps1")
	if err := os.WriteFile(ps1, []byte(script), 0644); err != nil {
		fmt.Println("Error escribiendo el script:", err)
		pause()
		return
	}
	cmd := exec.Command("powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ps1)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	_ = cmd.Run()
	pause()
}
