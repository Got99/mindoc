// template_fun 文件提供与 template_fun 主题相关的通用工具函数。
// 这些工具会被控制器、模型、导出流程和外部集成复用，用来减少重复实现。
package utils

func Asset(p string, cdn string) string {
	return cdn + p
}
