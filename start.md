# MinDoc 接手与读码指南

这份文档是写给第一次接手 MinDoc 代码的人看的。

如果你现在的感觉是：

- 仓库文件很多，不知道从哪开始
- 看 Controller 时感觉变量来路不明
- 看 Model 时又不知道它是被谁调用的
- 想改一个功能，但连链路都没有建立起来

那就按这份文档来。

本文的目标不是把所有文件逐个解释完，而是先帮你建立一套足够稳定的理解框架，让你能够：

1. 知道程序是怎么启动起来的。
2. 知道一个请求是如何穿过路由、控制器、模型和模板的。
3. 知道项目里哪些目录是核心，哪些是配套。
4. 知道要改某个功能时，应该先追哪几个文件。
5. 知道这个项目里最容易让人误判的地方在哪里。

## 1. 先用一句话理解这个项目

MinDoc 是一个基于 Beego 的 Go Web 应用，它的核心业务是“知识库/项目文档管理”。

从工程结构看，它不是前后端分离项目，也不是严格分层的现代架构，更接近传统 Go Web 应用：

- Beego 负责 Web 路由、模板、Session、配置加载
- Controller 负责请求编排
- Model 负责数据库结构和主要业务动作
- View 使用服务端模板渲染 HTML
- `static/` 提供 JS、CSS、图片等静态资源

你可以先把整个项目记成：

`main.go -> commands 初始化 -> routers 路由/过滤器 -> controllers -> models -> views`

这是理解 MinDoc 的主骨架。

## 2. 目录总览

先对照目录建立地图，后面读代码就不容易迷路。

### 2.1 核心目录

- `main.go`
  程序入口。

- `commands/`
  启动装配层。负责读配置、初始化数据库、缓存、日志、模板函数，以及安装、更新、修改密码等命令。

- `commands/daemon/`
  守护进程/服务模式入口。真正跑 Web 服务时会走这里。

- `routers/`
  路由注册和过滤器。URL 先在这里决定被谁接，再决定哪些请求要被提前拦截。

- `controllers/`
  HTTP 请求处理层。负责取参数、鉴权、调用模型、返回 JSON 或渲染模板。

- `models/`
  数据模型和主要业务逻辑。很多真正的“动作”都在这里，不只是查库。

- `views/`
  服务端模板。页面最终由这些 `.tpl` 生成。

- `conf/`
  配置样例、常量、URL 和一些运行时配置访问封装。

- `utils/`
  通用工具，比如加密、文件操作、分页、认证、导出辅助等。

### 2.2 配套目录

- `static/`
  前端静态资源。

- `uploads/`
  上传文件目录。

- `cache/`
  对 Beego Cache 的一层包装。

- `graphics/`
  文件和图片相关辅助逻辑。

- `mail/`
  邮件发送能力。

- `mcp/`
  MCP Server 相关逻辑和中间件。

- `lib/`
  运行时依赖的字典、字体、时区数据等。

## 3. 程序启动链路

这一节最重要。第一次接手时，建议一定从启动链路读。

推荐顺序：

1. `main.go`
2. `commands/daemon/daemon.go`
3. `commands/command.go`
4. `routers/router.go`
5. `routers/filter.go`

### 3.1 `main.go` 只做入口分发

`main.go` 本身并不复杂，但它决定了程序进入哪条路径。

它主要做了几件事：

- 处理 `service install/remove/restart`
- 调用 `commands.RegisterCommand()`
- 创建 `daemon.NewDaemon()`
- 在非 Windows 且不是通过外部 daemon 拉起时，走 `kardianos/service`
- 否则直接执行 `d.Run()`

这意味着 MinDoc 既可以：

- 直接当普通命令行程序运行
- 也可以作为系统服务运行

所以你看到的“程序启动”其实不只一种模式。

### 3.2 真正跑 Web 服务的是 `daemon.Run()`

`commands/daemon/daemon.go` 里的 `Run()` 才是服务启动的真正装配点。

它按顺序做了下面这些事：

1. `commands.ResolveCommand(...)`
2. `commands.RegisterFunction()`
3. `commands.RegisterAutoLoadConfig()`
4. `commands.RegisterError()`
5. `web.ErrorController(&controllers.ErrorController{})`
6. 输出版本、构建时间、启动目录
7. `web.Run()`

可以把它理解成：

`命令参数解析 + 全局初始化 + 错误页注册 + 启动 Beego`

### 3.3 `ResolveCommand()` 是真正的初始化总入口

如果你只记一个关键函数，优先记 `commands.ResolveCommand()`。

这个函数承担了几乎所有运行前准备工作：

- 解析命令行参数 `-config`、`-dir`、`-log`
- 确定工作目录 `conf.WorkingDirectory`
- 确定配置文件路径 `conf.ConfigurationFile`
- 如果 `conf/app.conf` 不存在，则从 `conf/app.conf.example` 复制一份
- 读取配置文件 `web.LoadAppConfig(...)`
- 建立静态目录映射 `/static`、`/uploads`
- 指定视图目录 `views`
- 设置上传大小
- 读取字体
- 初始化数据库
- 初始化缓存
- 注册 ORM 模型
- 初始化日志
- 修复缺失索引
- 支持通过命令修改密码

这就是为什么你会发现：

- 配置读取不在 `main.go`
- 数据库初始化也不在 `main.go`
- 缓存、日志、模板函数也不是在同一层随手写的

整个系统是由 `ResolveCommand()` 装配起来的。

### 3.4 安装模式会做什么

第一次安装常用命令是：

```bash
./mindoc install
```

这条命令最终会走到 `commands/install.go`。

安装逻辑主要做了：

- `RunSyncdb` 初始化数据库表
- 初始化系统配置 `Option`
- 加载默认语言包
- 创建默认管理员 `admin / 123456`
- 创建默认演示项目 `mindoc`
- 创建默认项目空间

这点非常重要，因为它说明系统不是完全“空库启动”，而是自带初始化数据的。

如果你后面排查“为什么一启动就有 admin 和示例项目”，答案就在这里。

### 3.5 配置支持自动热加载，但不是全部生效

`commands.RegisterAutoLoadConfig()` 会监听配置文件变更。

它能在配置文件修改后重新加载：

- 配置项
- 缓存配置
- 日志配置

但代码里已经写明：

- 监听端口
- 数据库配置

这些不能靠热加载完全生效。

所以别把它理解成“全量动态配置系统”，它只覆盖一部分运行时行为。

## 4. 路由层怎么理解

路由相关代码主要在：

- `routers/router.go`
- `routers/filter.go`

### 4.1 `router.go` 是“功能地图”

这个文件很长，但并不适合逐行死读。

更高效的读法是按模块分区看：

- `/login` `/logout` `/register`
  用户登录注册和认证。

- `/manager/*`
  系统后台。

- `/setting/*`
  当前用户设置。

- `/book/*`
  项目管理，包括项目设置、成员、团队、排序等。

- `/manage/blogs/*`
  博客管理。

- `/api/*`
  文档编辑相关接口。

- `/docs/*`
  文档阅读和搜索。

- `/history/*`
  文档历史。

- `/comment/*`
  评论。

- `/mcp/*`
  MCP Server 接口。

当你想理解某个功能时，先从这里找 URL 对应哪个 Controller 方法，这是最快的入口。

### 4.2 `filter.go` 是第一层访问控制

这里主要插入了几类过滤器：

- 对 `/manager`、`/setting`、`/book`、`/api`、`/manage` 等路径做登录校验
- 对 `/mcp/*` 接口加认证中间件
- 在请求开始时校验 Session Cookie 的格式
- 在请求阶段给响应追加版本等响应头

这说明权限并不是只在 Controller 层处理。

如果你发现某个请求根本没进入目标方法，就已经：

- 被跳转到登录页
- 返回 Ajax 未登录响应
- 被直接拒绝

先查 `routers/filter.go`，再查 Controller。

## 5. 一次请求是怎么流转的

先看最典型的场景：阅读一篇文档。

对应路由是：

`/docs/:key/:id`

实际流转过程大致如下：

1. 请求进入 Beego
2. 先经过 `filter.go` 中的全局过滤器
3. 根据 `router.go` 命中 `DocumentController.Read`
4. `DocumentController` 的 `Prepare()` 来自 `BaseController`
5. 基类准备用户、语言、系统选项、模板公共数据
6. `Read()` 读取项目和文档信息
7. `models.Document` 优先查缓存，再回源数据库
8. 拼装附件、目录树、上下篇导航
9. 设置模板变量
10. 渲染 `views/document/*_read.tpl`

这就是 MinDoc 最常见的处理方式：

`Router -> Filter -> BaseController.Prepare -> 具体 Controller -> Model -> View`

## 6. BaseController 是整个系统的公共入口

第一次读 Controller 前，建议先完整看一遍：

- `controllers/BaseController.go`

这是个非常关键的基类。

### 6.1 `Prepare()` 里做了什么

`Prepare()` 会提前准备很多上下文：

- 读取当前登录用户
- 支持从 remember cookie 恢复登录
- 把当前用户写入 `c.Member`
- 读取系统设置表 `Option`
- 把选项写入 `c.Option`
- 把很多选项放进 `c.Data`
- 计算 `BaseUrl`
- 读取脚本模板片段
- 设置当前语言 `Lang`
- 判断是否允许匿名访问
- 判断是否启用文档历史

所以很多 Controller 方法虽然没显式初始化这些值，但其实已经可用了：

- `c.Member`
- `c.Option`
- `c.Lang`
- `c.EnableAnonymous`
- `c.EnableDocumentHistory`
- `c.Data[...]`

### 6.2 为什么很多变量“看上去像凭空出现”

很多人第一次看这种项目会疑惑：

- `c.Member` 是谁赋值的
- `c.Data["BaseUrl"]` 为什么已经有值
- `c.Option["ENABLE_ANONYMOUS"]` 从哪来的

答案基本都在 `BaseController.Prepare()`。

如果你跳过基类，后面读 Controller 会非常痛苦。

## 7. 登录态和权限体系

接手业务系统时，登录和权限是第二个必须搞清楚的主题。

### 7.1 登录入口在 `AccountController`

相关文件：

- `controllers/AccountController.go`
- `models/Member.go`

`AccountController.Login()` 的主要逻辑是：

- 如果 Session 里已经有用户，直接跳转
- 如果 remember cookie 可恢复登录，就直接写回 Session
- POST 登录时校验验证码
- 调用 `models.NewMember().Login(account, password)`
- 登录成功后更新最后登录时间
- 把用户写入 Session
- 如果勾选 remember，则写入安全 Cookie

这说明系统登录态有两层：

- Session
- remember cookie

### 7.2 XSRF 校验在账户控制器里很明显

`AccountController.Prepare()` 里还做了 XSRF 检查：

- 读取 `_xsrf`
- 或从请求头里取 token
- 和 `XSRFToken()` 比较

如果不通过：

- Ajax 请求直接返回 JSON 错误
- 普通请求渲染错误页

这说明账户相关接口有独立的请求安全处理，而不是全部交给外部中间件。

### 7.3 项目权限不是“只有一种角色”

跟项目访问相关的核心模型包括：

- `models/Relationship.go`
- `models/Team.go`
- `models/TeamMember.go`
- `models/TeamRelationship.go`

其中 `Relationship` 表示“用户和项目的直接关系”。

角色定义在 `conf/enumerate.go`：

- `BookFounder`
- `BookAdmin`
- `BookEditor`
- `BookObserver`

也就是说，项目权限不是简单的“能看/不能看”，而是有层级角色的。

### 7.4 系统角色和项目角色不是一回事

这里要分清两个层次：

- 系统角色
  超级管理员、管理员、普通用户、只读用户。

- 项目角色
  创始人、管理员、编辑者、观察者。

很多新接手的人会把这两层混在一起，后面改权限逻辑时就容易出错。

## 8. 配置体系分两层

MinDoc 里有两类配置，必须分开理解。

### 8.1 部署配置：`conf/app.conf`

来源文件：

- `conf/app.conf.example`

这一层是程序运行依赖的外部配置，主要包括：

- 地址和端口
- 数据库连接
- Session 存储
- 缓存方式
- 日志
- 邮件
- LDAP
- 导出
- CDN
- 多语言
- MCP Server

这类配置更偏“部署时决定”。

### 8.2 系统设置：数据库里的 `Option`

`BaseController.Prepare()` 会读取 `models.NewOption().All()`。

这说明还有一层配置来自数据库表，而不是 `app.conf`。

这类配置更偏“系统运行中的业务开关”，例如：

- 是否允许匿名访问
- 是否启用文档历史
- 是否启用验证码

所以遇到一个行为时，你要先判断它受哪层控制：

- 部署配置
- 系统设置表

别只搜 `app.conf`。

## 9. Model 层不是“薄薄一层 ORM”

这点非常重要。

MinDoc 的 `models/` 不只是数据结构定义，很多真正的业务动作都写在这里。

### 9.1 以 `Book` 为例

核心文件：

- `models/BookModel.go`

`Book` 是知识库/项目的核心实体，它大致对应一个文档项目容器。

它有这些典型字段：

- `BookName`
- `Identify`
- `Description`
- `CommentStatus`
- `PrivatelyOwned`
- `PrivateToken`
- `BookPassword`
- `Editor`
- `Theme`
- `HistoryCount`
- `ItemId`
- `MemberId`

这些字段已经足够说明：一个 Book 不是简单目录，它承担了权限、展示、导出、编辑器类型等多种职责。

### 9.2 `Book.Insert()` 有明显副作用

创建项目时，不只是插入一条项目记录。

`Book.Insert()` 还会：

- 建立创建者和项目的关系
- 自动创建一篇初始化空白文档
- 处理标签相关逻辑

也就是说，很多业务动作在 MinDoc 里是“单入口，多副作用”。

你排查问题时不能只盯着一张表。

### 9.3 以 `Document` 为例

核心文件：

- `models/DocumentModel.go`

`Document` 代表项目中的一篇文档，它有几个关键内容字段：

- `Markdown`
  Markdown 源文。

- `Content`
  未发布的 HTML 内容。

- `Release`
  已发布的 HTML 内容。

这说明系统区分：

- 编辑中的内容
- 发布后的内容

如果你后面做编辑器、发布、预览相关功能，这个差异必须记住。

### 9.4 文档读取带缓存

`DocumentModel.go` 里有：

- `PutToCache()`
- `FromCacheById()`
- `FromCacheByIdentify()`

缓存包装在：

- `cache/cache.go`

它本质上是对 Beego Cache 的一层统一封装，序列化方式用的是 gob。

所以当你看到文档读取性能相关逻辑时，不要只看数据库查询，还要看缓存命中链路。

### 9.5 发布不是简单字段赋值

`Document.ReleaseContent()` 会把 `Content` 处理后同步到 `Release`，再持久化。

这类方法说明文档内容在系统里是有“状态转换”的，不只是存一份字符串。

## 10. Controller 层怎么读

Controller 层的作用可以概括成四件事：

- 接收参数
- 校验权限
- 调用模型
- 决定返回 JSON 还是页面

### 10.1 `BookController`

建议先读：

- `controllers/BookController.go`

因为它能帮助你建立“项目 Book 是系统一级业务对象”的感觉。

重点方法：

- `Index()`
  我的项目列表。

- `Dashboard()`
  项目概览页。

- `Setting()`
  项目设置页。

- `SaveBook()`
  保存项目设置。

读这类方法时，建议看固定套路：

1. 是否调用 `Prepare()`
2. 从哪里取参数
3. 调了哪个 Model
4. 做了哪些权限判断
5. 往 `c.Data` 塞了什么
6. 最终是 `TplName` 还是 `JsonResult`

### 10.2 `DocumentController`

建议再读：

- `controllers/DocumentController.go`

这是另一个核心控制器。

它覆盖的能力非常多：

- 阅读
- 编辑
- 搜索
- 历史
- 附件
- 导出
- 二维码

#### `Index()`

这是项目文档首页，主要做：

- 判断项目是否可读
- 确定使用哪个阅读模板
- 读取第一篇文档或项目描述
- 生成文档树
- 渲染首页

#### `Read()`

这是最值得跟的一条链路，里面能看到：

- 读取文档参数
- 判断匿名访问/登录态
- 判定项目可读性
- 优先从缓存读取文档
- 读取附件
- 生成上下篇导航
- 增加浏览量
- Ajax 与页面两种返回方式

如果你能把 `Read()` 彻底看懂，整个系统的阅读链路就基本建立起来了。

## 11. View 层不是附属品，而是完整页面的一部分

MinDoc 不是前后端分离项目，所以模板层很重要。

相关目录：

- `views/book/`
- `views/document/`
- `views/manager/`
- `views/account/`
- `views/blog/`

典型方式是：

- Controller 指定 `TplName`
- 把数据塞进 `c.Data`
- 模板直接读取这些数据渲染页面

所以改一个页面问题时，通常要同时看：

- 路由
- Controller
- 模板
- 静态资源

不要只改一层。

## 12. 这个项目里的几个核心对象

第一次接手时，请优先建立下面这些实体的心智模型。

### 12.1 Member

用户。

相关关注点：

- 账号密码登录
- 第三方认证
- Session
- remember cookie
- 系统角色

### 12.2 Book

项目、知识库。

它是一级业务容器，下面挂很多内容：

- 文档
- 成员关系
- 评论设置
- 阅读权限
- 导出行为
- 编辑器类型

### 12.3 Document

文档内容本体。

你后面改阅读、编辑、历史、发布、目录树时，基本都绕不开它。

### 12.4 Relationship

项目和用户的关系表。

它是判断某个用户在某个项目里是什么角色的核心数据来源之一。

### 12.5 Option

系统设置表。

它和 `app.conf` 的职责不同，不要混用概念。

## 13. 常见功能应该从哪里追

如果你已经有一个具体功能目标，不要继续大面积泛读，直接按下面入口追。

### 13.1 登录问题

先看：

- `routers/router.go`
- `controllers/AccountController.go`
- `models/Member.go`
- `controllers/BaseController.go`

### 13.2 阅读一篇文档

先看：

- `routers/router.go` 中 `/docs/:key/:id`
- `controllers/DocumentController.go` 的 `Read()`
- `models/DocumentModel.go`
- `views/document/*_read.tpl`

### 13.3 创建项目

先看：

- `controllers/BookController.go`
- `models/BookModel.go`
- `models/Relationship.go`
- `models/DocumentModel.go`

### 13.4 项目权限问题

先看：

- `routers/filter.go`
- `controllers/BookController.go`
- `models/Relationship.go`
- `models/Team*.go`
- `conf/enumerate.go`

### 13.5 配置不生效

先看：

- `conf/app.conf`
- `commands/command.go`
- `models/Option`
- `controllers/BaseController.go`

## 14. 推荐的读码顺序

如果你现在完全没有方向，按下面顺序最稳：

1. `main.go`
2. `commands/daemon/daemon.go`
3. `commands/command.go`
4. `commands/install.go`
5. `routers/router.go`
6. `routers/filter.go`
7. `controllers/BaseController.go`
8. `controllers/AccountController.go`
9. `controllers/BookController.go`
10. `controllers/DocumentController.go`
11. `models/BookModel.go`
12. `models/DocumentModel.go`
13. `models/Relationship.go`
14. `conf/app.conf.example`
15. `conf/enumerate.go`

这个顺序的核心原则是：

- 先搞清启动
- 再搞清路由入口
- 再搞清控制器如何编排
- 最后再下沉到数据模型

不要一开始就钻在 `models/` 里硬啃，会很容易丢掉方向。

## 15. 最容易让人误解的几个点

### 15.1 不是所有逻辑都在 Controller

很多核心动作在 Model 里完成，比如：

- 创建项目时自动创建关系和空白文档
- 文档读取时带缓存
- 发布有状态转换

所以不要把 Model 理解成“纯数据库映射”。

### 15.2 不是所有权限都在一个地方

权限分散在几层：

- 过滤器
- Controller
- Model 查询逻辑

遇到权限问题时不要只搜一处。

### 15.3 不是所有配置都来自 `app.conf`

有些来自配置文件，有些来自数据库 `Option`。

这两层混起来看，会非常容易误判。

### 15.4 这个项目不是前后端分离

很多行为是页面模板、接口和静态 JS 共同完成的。

所以页面问题经常需要跨层排查。

## 16. 调试和读码建议

这里给你一个很务实的建议：以后不要再按“目录顺序”看代码，按“功能链路”看。

### 16.1 最好的方式：从 URL 开始

例如你想看“编辑文档”：

1. 先在 `routers/router.go` 找对应路由
2. 进入对应 Controller 方法
3. 看它调用哪些 Model
4. 看最后用哪个模板或返回哪个 JSON
5. 如果页面还有交互，再找模板里引用的 JS

这种方式最不容易迷路。

### 16.2 第二好的方式：从实体开始

如果你想彻底理解 `Book`：

1. 先看 `models/BookModel.go`
2. 再搜 `NewBook()` / `NewBookResult()`
3. 看它被哪些 Controller 调用
4. 看相关模板怎么展示它

这种方式更适合理解业务结构。

### 16.3 别急着重构

第一次接手这类项目时，最危险的动作是“还没完全理解链路就开始重构”。

更稳妥的方法是：

- 先沿一条功能链路跑通
- 再做很小的修改
- 修改后重新走一遍链路验证

## 17. 如果你现在就想开始动手

最适合上手的第一个目标，不是改一个很大的功能，而是做一件“链路短、反馈清楚”的事情。

推荐你从下面几类里选一个开始：

- 改登录页上的一个展示字段
- 改项目设置页上的一个表单项
- 改文档阅读页上的一段模板内容
- 给某个 JSON 接口补一个字段

因为这几类任务能迫使你完整走一遍：

- 路由
- Controller
- Model
- View

而不会一下子掉进太深的业务细节里。

## 18. 一页版总结

如果你只想记住最关键的东西，记下面这些就够了：

- 程序入口在 `main.go`
- 真正的启动装配在 `commands/daemon/daemon.go` 和 `commands/command.go`
- 路由和前置拦截在 `routers/`
- 公共上下文准备在 `BaseController.Prepare()`
- 主要业务动作在 `models/`，不是只有查库
- 页面是服务端模板，不是前后端分离
- 配置分两层：`app.conf` 和数据库 `Option`
- 最好的读法是按功能链路追，不是按目录硬读

---

如果你接下来还想继续深化，我建议下一份文档优先写这三类之一：

- 登录与权限体系详解
- Book / Document / Relationship 的数据关系图
- 文档阅读、编辑、发布的完整调用链
