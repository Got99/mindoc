// ConvertBookResult 文件定义了与 ConvertBookResult 相关的数据结构和业务操作。
// 在 MinDoc 中，模型层不仅负责 ORM 映射，也经常承载围绕该对象的实际业务逻辑。
package models

// 转换结果
type ConvertBookResult struct {
	PDFPath  string
	EpubPath string
	MobiPath string
	WordPath string
}
