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



```bash
curl -X POST 'http://192.168.88.99:18181/api/blog/append?token=Pg79bIss25B9' \
  -H 'Content-Type: application/json' \
  -d '{
    "blog_id": 1,
     "position": "head",
    "content": "\n## 20250329 \n版本1 \n 更新: 无可无不可"
  }'


```