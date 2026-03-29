// gob 文件提供与 gob 主题相关的通用工具函数。
// 这些工具会被控制器、模型、导出流程和外部集成复用，用来减少重复实现。
package utils

import (
	"bytes"
	"encoding/gob"
)

//解码
func Decode(value string, r interface{}) error {

	network := bytes.NewBuffer([]byte(value))

	dec := gob.NewDecoder(network)

	return dec.Decode(r)
}

//编码
func Encode(value interface{}) (string, error) {
	network := bytes.NewBuffer(nil)

	enc := gob.NewEncoder(network)

	err := enc.Encode(value)
	if err != nil {
		return "", err
	}

	return network.String(), nil
}
