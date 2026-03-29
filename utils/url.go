// url 文件提供与 url 主题相关的通用工具函数。
// 这些工具会被控制器、模型、导出流程和外部集成复用，用来减少重复实现。
package utils

import (
	"strings"
)

func JoinURI(elem ...string) string {
	if len(elem) <= 0 {
		return ""
	}
	uri := ""

	for i, u := range elem {
		u = strings.Replace(u, "\\", "/", -1)

		if i == 0 {
			if !strings.HasSuffix(u, "/") {
				u = u + "/"
			}
			uri = u
		} else {
			u = strings.Replace(u, "//", "/", -1)
			if strings.HasPrefix(u, "/") {
				u = string(u[1:])
			}
			uri += u
		}
	}
	return uri
}