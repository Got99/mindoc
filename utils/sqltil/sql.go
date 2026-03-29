// sql 文件提供与 sql 主题相关的通用工具函数。
// 这些工具会被控制器、模型、导出流程和外部集成复用，用来减少重复实现。
package sqltil

import "strings"

//转义like语法的%_符号
func EscapeLike(keyword string) string {
	return strings.Replace(strings.Replace(keyword,"_","\\_",-1),"%","\\%",-1)
}
