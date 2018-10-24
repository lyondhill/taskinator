package main

import (
	"fmt"
	"github.com/spf13/cobra"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

var rootCmd = &cobra.Command{
	Use:   "taskinator",
	Short: "create a bunch of tasks for a token and organization",
	Run:   runner,
}

var token string
var org string
var host string

func init() {
	rootCmd.Flags().StringVarP(&token, "token", "", "", "token")
	rootCmd.Flags().StringVarP(&host, "host", "", "", "host")
	rootCmd.Flags().StringVarP(&org, "org-id", "", "", "organization")
	rootCmd.MarkFlagRequired("token")
	rootCmd.MarkFlagRequired("host")
	rootCmd.MarkFlagRequired("org-id")
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func runner(cmd *cobra.Command, args []string) {
	fmt.Printf("running task create for %d arguements\n", len(args))

	for _, arg := range args {
		abs, err := filepath.Abs(arg)
		if err != nil {
			fmt.Println("this file has no path", err)
			continue
		}
		file, err := os.Open(arg)
		if err != nil {
			fmt.Println("Um.. ERROR opening file..", err)
			continue
		}

		info, err := file.Stat()
		if err != nil {
			fmt.Println("cant stat file", err)
			continue
		}

		if info.IsDir() {
			fmt.Println("You gave me a directory. ok I can handle this. We have trained for this.")
			infos, err := file.Readdir(0)
			if err != nil {
				fmt.Println("Cant read directory", err)
				continue
			}

			for _, inf := range infos {

				if inf.IsDir() {
					fmt.Println("ok you got me. Subdirectories are hard..")
				}

				doIt(filepath.Join(abs, inf.Name()))
			}
			continue
		}
		doIt(abs)
	}
}

func doIt(file string) {
	if !strings.HasSuffix(file, ".flux") {
		return
	}

	fmt.Println("Lets do this:", file)
	cmd := exec.Command("influx", "--host", host, "--token", token, "--org-id", org, "task", "create", "@"+file)
	out, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("error processing", err)
	}
	fmt.Printf("output:\n%s\n", out)
}
