// ErrorController.go 定义了全局错误页控制器。
// 当请求被框架判定为 403、404、500 等错误时，会由这里选择对应的模板进行渲染。
package controllers

type ErrorController struct {
	BaseController
}

func (c *ErrorController) Error404() {
	c.TplName = "errors/404.tpl"
}

func (c *ErrorController) Error403() {
	c.TplName = "errors/403.tpl"
}

func (c *ErrorController) Error500() {
	c.TplName = "errors/error.tpl"
}
