// android_time 文件提供与 android_time 主题相关的通用工具函数。
// 这些工具会被控制器、模型、导出流程和外部集成复用，用来减少重复实现。
package utils

import (
	"os/exec"
	"strings"
	"time"
)

func FixTimezone() {
	out, err := exec.Command("/system/bin/getprop", "persist.sys.timezone").Output()
	if err != nil {
		return
	}
	timeZone, err := time.LoadLocation(strings.TrimSpace(string(out)))
	if err != nil {
		return
	}
	time.Local = timeZone
}
