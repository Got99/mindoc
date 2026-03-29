// main.go 是 MinDoc 的程序入口。
// 这里负责识别命令行启动模式，并在命令模式、系统服务模式和普通 Web 服务模式之间做分发。
package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	_ "github.com/beego/beego/v2/server/web/session/memcache"
	_ "github.com/beego/beego/v2/server/web/session/mysql"
	_ "github.com/beego/beego/v2/server/web/session/redis"
	"github.com/kardianos/service"
	_ "github.com/mattn/go-sqlite3"
	"github.com/mindoc-org/mindoc/commands"
	"github.com/mindoc-org/mindoc/commands/daemon"
	_ "github.com/mindoc-org/mindoc/routers"
	"github.com/mindoc-org/mindoc/utils"
)

func isViaDaemonUnix() bool {
	parentPid := os.Getppid()

	// 通过父进程命令行判断当前进程是否由 mindoc-daemon 拉起。
	cmdLineBytes, err := ioutil.ReadFile(fmt.Sprintf("/proc/%d/cmdline", parentPid))
	if err != nil {
		return false
	}

	cmdLine := string(cmdLineBytes)
	executable := strings.Split(cmdLine, " ")[0]
	fmt.Printf("Parent executable: %s\n", executable)
	filename := filepath.Base(executable)
	return strings.Contains(filename, "mindoc-daemon")
}

func main() {

	// service 子命令用于安装、卸载或重启系统服务。
	if len(os.Args) >= 3 && os.Args[1] == "service" {
		if os.Args[2] == "install" {
			daemon.Install()
		} else if os.Args[2] == "remove" {
			daemon.Uninstall()
		} else if os.Args[2] == "restart" {
			daemon.Restart()
		}
	}

	// 处理 install、update、version 等命令行模式；普通启动会继续往下走。
	commands.RegisterCommand()

	d := daemon.NewDaemon()

	// 安卓 go/src/time/zoneinfo_android.go 固定localLoc 为 UTC
	if runtime.GOOS == "android" {
		utils.FixTimezone()
	}

	// 在 Unix 环境下，优先通过 kardianos/service 进入服务生命周期；
	// 如果当前已经是由外部 daemon 拉起，或者运行在 Windows，则直接执行 d.Run()。
	if runtime.GOOS != "windows" && !isViaDaemonUnix() {
		s, err := service.New(d, d.Config())

		if err != nil {
			fmt.Println("Create service error => ", err)
			os.Exit(1)
		}

		if err := s.Run(); err != nil {
			log.Fatal("启动程序失败 ->", err)
		}
	} else {
		d.Run()
	}

}
