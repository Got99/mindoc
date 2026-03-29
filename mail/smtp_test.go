// smtp_test.go 用于验证邮件发送模块的核心行为。
// 这些测试通常覆盖 SMTP 配置解析或消息发送相关的基础正确性。
package mail

import (
	// "os"
	"testing"
)

func TestSend(t *testing.T) {
	/*
	conf := &SMTPConfig{
		Username: "swh@adm***.com",
		Password: "",
		Host:     "smtp.exmail.qq.com",
		Port:     465,
		Secure:   "SSL",
	}
	c := NewSMTPClient(conf)
	m := NewMail()
	m.AddTo("brother <1556****@qq.com>")
	m.AddFrom("hank <" + conf.Username + ">")
	m.AddSubject("Testing")
	m.AddText("Some text :)")
	filepath, _ := os.Getwd()
	m.AddAttachment(filepath + "/README.md")
	if e := c.Send(m); e != nil {
		t.Error(e)
	} else {
		t.Log("发送成功")
	}
	*/
}
