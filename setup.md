###  环境变量配置
```bash
# mindoc 
export MINDOC_DB_ADAPTER=mysql
export MINDOC_DB_HOST=192.168.88.88
export MINDOC_DB_PORT=3306
export MINDOC_DB_DATABASE=mindoc
export MINDOC_DB_USERNAME=root
export MINDOC_DB_PASSWORD=DeviSa@Sa
export MINDOC_PORT=18181
```

### 启动安装 
1. 会创建数据库
```
go run main.go install
```

2. 启动
```
go run main.go 
```

3. 更新 
```
go run main.go update 
```

### 博客 Markdown 内容 API

```bash
curl -sS -X POST \
  'http://127.0.0.1:8181/api/v1/blog/content' \
  -H 'Authorization: Bearer YOUR_BLOG_API_TOKEN' \
  -H 'Content-Type: application/json' \
  --data-binary '{
    "content": "## 标题\n追加内容",
    "type": "add",
    "position": "tail"
  }'
```
覆盖
```
{
  "content": "## 全新的文档\n正文",
  "type": "overwrite"
}
```